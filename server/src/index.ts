// Dream Isles online relay: routes WebSocket connections to the lobby and the rooms.
//   /health            → "ok"
//   /host        (ws)  → a new room; the caller is its host
//   /join/<CODE> (ws)  → that room
//   /queue?v=<v> (ws)  → quick match
import { claimRoom, type Env } from "./claim";
import { isCode } from "./codes";

export { Lobby } from "./lobby";
export { Room } from "./room";

function upgrade(request: Request): boolean {
  return request.headers.get("Upgrade") === "websocket";
}

function toRoom(env: Env, code: string, role: "host" | "join", request: Request): Promise<Response> {
  const url = `https://room/ws?role=${role}&code=${encodeURIComponent(code)}`;
  return env.ROOM.get(env.ROOM.idFromName(code)).fetch(new Request(url, request));
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    if (path === "/health") return new Response("ok");
    if (path === "/host") {
      if (!upgrade(request)) return new Response("expected a websocket", { status: 426 });
      return toRoom(env, await claimRoom(env, false), "host", request);
    }
    if (path.startsWith("/join/")) {
      const code = decodeURIComponent(path.slice("/join/".length));
      if (!isCode(code)) return new Response("bad room code", { status: 400 });
      if (!upgrade(request)) return new Response("expected a websocket", { status: 426 });
      return toRoom(env, code, "join", request);
    }
    if (path === "/queue") {
      return env.LOBBY.get(env.LOBBY.idFromName("lobby")).fetch(request);
    }
    return new Response("not found", { status: 404 });
  },
} satisfies ExportedHandler<Env>;
