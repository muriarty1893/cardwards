// Quick match: one Lobby object holds the players who are searching, tagged by game version.
// When a second player with the same version arrives, both get a fresh room code and are let go.
import { DurableObject } from "cloudflare:workers";
import { claimRoom, type Env } from "./claim";

export class Lobby extends DurableObject<Env> {
  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade") !== "websocket") return new Response("expected a websocket", { status: 426 });
    const v = new URL(request.url).searchParams.get("v") ?? "";
    if (v === "" || v.length > 32) return new Response("missing version", { status: 400 });
    const [client, server] = Object.values(new WebSocketPair());
    this.ctx.acceptWebSocket(server, [v]);
    const partner = this.ctx.getWebSockets(v).find((ws) => ws !== server && ws.readyState === WebSocket.READY_STATE_OPEN);
    if (partner) {
      const code = await claimRoom(this.env, true);
      const text = JSON.stringify({ t: "matched", code });
      for (const ws of [partner, server]) {
        try {
          ws.send(text);
          ws.close(1000, "matched");
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
}
