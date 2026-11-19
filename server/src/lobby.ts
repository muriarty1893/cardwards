// Quick match: one Lobby object holds the players who are searching, tagged by game version.
// When a second player with the same version arrives, both get a fresh room code. The clients close
// their lobby sockets themselves: closing the newest socket here, before its handshake has finished,
// can make the client see the close without the message. Matched sockets are marked so they are
// never matched again, and closed on a later visit if a client never closed them.
import { DurableObject } from "cloudflare:workers";
import { claimRoom, type Env } from "./claim";

type Attachment = { matchedAt: number | null };

/** How long a matched socket may stay open before the lobby closes it. */
const MATCHED_GRACE_MS = 10_000;

export class Lobby extends DurableObject<Env> {
  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade") !== "websocket") return new Response("expected a websocket", { status: 426 });
    const v = new URL(request.url).searchParams.get("v") ?? "";
    if (v === "" || v.length > 32) return new Response("missing version", { status: 400 });
    const now = Date.now();
    this.closeStale(now);
    const [client, server] = Object.values(new WebSocketPair());
    this.ctx.acceptWebSocket(server, [v]);
    server.serializeAttachment({ matchedAt: null } satisfies Attachment);
    const partner = this.ctx
      .getWebSockets(v)
      .find((ws) => ws !== server && ws.readyState === WebSocket.READY_STATE_OPEN && !this.matched(ws));
    if (partner) {
      const code = await claimRoom(this.env, true);
      const text = JSON.stringify({ t: "matched", code });
      for (const ws of [partner, server]) {
        ws.serializeAttachment({ matchedAt: now } satisfies Attachment);
        try {
          ws.send(text);
        } catch {}
      }
    }
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(): Promise<void> {}

  async webSocketClose(ws: WebSocket): Promise<void> {
    try {
      ws.close(1000, "bye");
    } catch {}
  }

  private matched(ws: WebSocket): boolean {
    return (ws.deserializeAttachment() as Attachment | null)?.matchedAt != null;
  }

  private closeStale(now: number): void {
    for (const ws of this.ctx.getWebSockets()) {
      const at = (ws.deserializeAttachment() as Attachment | null)?.matchedAt;
      if (at != null && now - at > MATCHED_GRACE_MS) {
        try {
          ws.close(1000, "matched");
        } catch {}
      }
    }
  }
}
