import { SELF } from "cloudflare:test";
import type { ServerMsg } from "../src/protocol";

/** A test client socket that buffers what it receives. */
export interface Client {
  ws: WebSocket;
  msgs: ServerMsg[];
  closed: { code: number } | null;
  send(m: unknown): void;
  /** Resolves with the next message of type `t` (waiting up to 2 s). */
  next<T extends ServerMsg["t"]>(t: T): Promise<Extract<ServerMsg, { t: T }>>;
  waitClosed(): Promise<number>;
}

export async function connect(path: string): Promise<Client> {
  const res = await SELF.fetch(`http://relay${path}`, { headers: { Upgrade: "websocket" } });
  if (!res.webSocket) throw new Error(`no websocket for ${path}: ${res.status}`);
  const ws = res.webSocket;
  ws.accept();
  const c: Client = {
    ws,
    msgs: [],
    closed: null,
    send: (m) => ws.send(typeof m === "string" ? m : JSON.stringify(m)),
    async next(t) {
      for (let i = 0; i < 200; i++) {
        const k = c.msgs.findIndex((m) => m.t === t);
        if (k >= 0) return c.msgs.splice(k, 1)[0] as never;
        await new Promise((r) => setTimeout(r, 10));
      }
      throw new Error(`no ${t} message; got ${JSON.stringify(c.msgs)}`);
    },
    async waitClosed() {
      for (let i = 0; i < 200 && !c.closed; i++) await new Promise((r) => setTimeout(r, 10));
      if (!c.closed) throw new Error("socket did not close");
      return c.closed.code;
    },
  };
  ws.addEventListener("message", (e) => c.msgs.push(JSON.parse(e.data as string)));
  ws.addEventListener("close", (e) => (c.closed = { code: e.code }));
  return c;
}
