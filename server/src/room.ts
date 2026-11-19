// One Durable Object per room code: sockets ⇄ referee, the room saved in storage, timers on the alarm.
import { DurableObject } from "cloudflare:workers";
import { LIMITS, byteLength, parseClient, type Seat, type ServerMsg } from "./protocol";
import { Referee, type Out, type RoomState } from "./referee";

type Attachment = { role: "host" | "join"; seat: Seat | null; replaced?: boolean };

export class Room extends DurableObject {
  private ref: Referee | null = null;
  /** Arrival times of each socket's recent messages (flood guard). */
  private rate = new Map<WebSocket, number[]>();

  /** Reserve this room for a new code. False when the code is already in use. */
  async claim(code: string, quick: boolean): Promise<boolean> {
    if (await this.load()) return false;
    this.ref = new Referee(Referee.fresh(code, quick, Date.now()));
    await this.persist();
    return true;
  }

  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade") !== "websocket") return new Response("expected a websocket", { status: 426 });
    const role = new URL(request.url).searchParams.get("role") === "host" ? "host" : "join";
    const [client, server] = Object.values(new WebSocketPair());
    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({ role, seat: null } satisfies Attachment);
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws: WebSocket, raw: string | ArrayBuffer): Promise<void> {
    if (typeof raw !== "string" || byteLength(raw) > LIMITS.maxBytes || this.flooding(ws)) {
      ws.close(1008, "too much");
      return;
    }
    const msg = parseClient(raw);
    if (!msg) return;
    const att = ws.deserializeAttachment() as Attachment;
    const ref = await this.load();
    const now = Date.now();
    if (att.seat === null) {
      if (msg.t !== "hello") return;
      if (!ref) return this.refuse(ws, { t: "error", code: "no_room", msg: "No room with that code" });
      const r = ref.hello(att.role, msg, now);
      if (r.error || r.seat === null) {
        return this.refuse(ws, { t: "error", code: r.error?.code ?? "bad_hello", msg: r.error?.msg ?? "" });
      }
      for (const old of this.ctx.getWebSockets()) {
        const a = old.deserializeAttachment() as Attachment;
        if (old !== ws && a.seat === r.seat) {
          old.serializeAttachment({ ...a, seat: null, replaced: true } satisfies Attachment);
          try {
            old.close(1000, "replaced");
          } catch {}
        }
      }
      ws.serializeAttachment({ ...att, seat: r.seat } satisfies Attachment);
      this.deliver(r.out);
      await this.persist();
      return;
    }
    if (!ref || msg.t === "hello") return;
    const out = ref.message(att.seat, msg, now);
    this.deliver(out);
    // Checksums alone change nothing worth a storage write.
    if (msg.t !== "hash" || out.length > 0) await this.persist();
  }

  async webSocketClose(ws: WebSocket): Promise<void> {
    this.rate.delete(ws);
    try {
      ws.close(1000, "bye");
    } catch {}
    const att = ws.deserializeAttachment() as Attachment | null;
    if (!att || att.seat === null || att.replaced) return;
    const ref = await this.load();
    if (!ref) return;
    this.deliver(ref.disconnect(att.seat, Date.now()));
    await this.persist();
  }

  async webSocketError(ws: WebSocket): Promise<void> {
    await this.webSocketClose(ws);
  }

  async alarm(): Promise<void> {
    const ref = await this.load();
    if (!ref) return;
    const now = Date.now();
    if (ref.dead(now)) {
      for (const ws of this.ctx.getWebSockets()) {
        try {
          ws.close(1000, "room closed");
        } catch {}
      }
      this.ref = null;
      await this.ctx.storage.deleteAlarm();
      await this.ctx.storage.deleteAll();
      return;
    }
    this.deliver(ref.tick(now));
    await this.persist();
  }

  private async load(): Promise<Referee | null> {
    if (this.ref) return this.ref;
    const s = await this.ctx.storage.get<RoomState>("room");
    if (s) this.ref = new Referee(s);
    return this.ref;
  }

  private async persist(): Promise<void> {
    if (!this.ref) return;
    await this.ctx.storage.put("room", this.ref.s);
    const next = this.ref.nextDeadline();
    if (next === null) await this.ctx.storage.deleteAlarm();
    else await this.ctx.storage.setAlarm(next);
  }

  private deliver(out: Out[]): void {
    if (out.length === 0) return;
    const sockets = this.ctx.getWebSockets();
    for (const o of out) {
      const text = JSON.stringify(o.msg);
      for (const ws of sockets) {
        if ((ws.deserializeAttachment() as Attachment).seat === o.to) {
          try {
            ws.send(text);
          } catch {}
        }
      }
    }
  }

  private refuse(ws: WebSocket, msg: ServerMsg): void {
    try {
      ws.send(JSON.stringify(msg));
      ws.close(1000, "refused");
    } catch {}
  }

  /** More than LIMITS.perSecond messages within any one second. */
  private flooding(ws: WebSocket): boolean {
    const now = Date.now();
    const times = this.rate.get(ws) ?? [];
    times.push(now);
    while (times.length > LIMITS.perSecond + 1) times.shift();
    this.rate.set(ws, times);
    return times.length > LIMITS.perSecond && now - times[0] < 1000;
  }
}
