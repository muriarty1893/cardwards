// Dream Isles online relay: routes WebSocket connections to the lobby and the rooms.
//   /health            → "ok"
//   /host        (ws)  → a new room; the caller is its host
//   /join/<CODE> (ws)  → that room
//   /queue?v=<v> (ws)  → quick match
// /host and /queue are limited per IP (gate.ts); over the limit the socket gets a "busy" error.
import { claimRoom, type Env } from "./claim";
import { isCode } from "./codes";
import { clientIp } from "./gate";
import type { ServerMsg } from "./protocol";
import { ERRORS } from "./referee";

export { Lobby } from "./lobby";
export { Room } from "./room";
export { Gate } from "./gate";

const BUSY: ServerMsg = { t: "error", code: "busy", msg: ERRORS.busy };

function upgrade(request: Request): boolean {
  return request.headers.get("Upgrade") === "websocket";
}

function toRoom(env: Env, code: string, role: "host" | "join", request: Request): Promise<Response> {
  const url = `https://room/ws?role=${role}&code=${encodeURIComponent(code)}`;
  return env.ROOM.get(env.ROOM.idFromName(code)).fetch(new Request(url, request));
}

/** False when this IP has opened too many rooms lately (see gate.ts). */
async function admitted(env: Env, request: Request): Promise<boolean> {
  const ip = clientIp(request);
  return ip === null || env.GATE.get(env.GATE.idFromName(ip)).allow();
}

/** A websocket that says why it was refused, then closes (clients can't read an HTTP status). */
function refuse(msg: ServerMsg): Response {
  const [client, server] = Object.values(new WebSocketPair());
  server.accept();
  server.send(JSON.stringify(msg));
  server.close(1000, "refused");
  return new Response(null, { status: 101, webSocket: client });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    if (path === "/health") return new Response("ok");
    if (path === "/host") {
      if (!upgrade(request)) return new Response("expected a websocket", { status: 426 });
      if (!(await admitted(env, request))) return refuse(BUSY);
      return toRoom(env, await claimRoom(env, false), "host", request);
    }
    if (path.startsWith("/join/")) {
      const code = decodeURIComponent(path.slice("/join/".length));
      if (!isCode(code)) return new Response("bad room code", { status: 400 });
      if (!upgrade(request)) return new Response("expected a websocket", { status: 426 });
      return toRoom(env, code, "join", request);
    }
    if (path === "/queue") {
      if (upgrade(request) && !(await admitted(env, request))) return refuse(BUSY);
      return env.LOBBY.get(env.LOBBY.idFromName("lobby")).fetch(request);
    }
    return new Response("not found", { status: 404 });
  },
} satisfies ExportedHandler<Env>;
