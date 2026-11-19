import { makeCode } from "./codes";
import type { Lobby } from "./lobby";
import type { Room } from "./room";

export interface Env {
  ROOM: DurableObjectNamespace<Room>;
  LOBBY: DurableObjectNamespace<Lobby>;
}

/** A fresh room code, reserved on its Room object (retries on the rare collision). */
export async function claimRoom(env: Env, quick: boolean): Promise<string> {
  for (let i = 0; i < 50; i++) {
    const code = makeCode(Math.random);
    if (await env.ROOM.get(env.ROOM.idFromName(code)).claim(code, quick)) return code;
  }
  throw new Error("no free room code");
}
