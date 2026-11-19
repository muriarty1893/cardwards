import { env } from "cloudflare:workers";
import { evictDurableObject } from "cloudflare:test";
import { describe, expect, it } from "vitest";
import { hello } from "./helpers";
import { connect } from "./ws";

async function hostAndJoin() {
  const host = await connect("/host");
  host.send(hello("Ann"));
  const welcome = await host.next("welcome");
  await host.next("waiting");
  const guest = await connect(`/join/${welcome.code}`);
  guest.send(hello("Bo"));
  const gw = await guest.next("welcome");
  const s0 = await host.next("start");
  const s1 = await guest.next("start");
  return { host, guest, code: welcome.code, tokens: [welcome.token, gw.token], s0, s1 };
}

describe("room over websockets", () => {
  it("host gets welcome + waiting with a code; join by that code starts both", async () => {
    const { s0, s1, code } = await hostAndJoin();
    expect(code).toMatch(/^[A-Z]{3,5}-[0-9]{2}$/);
    expect(s1).toEqual(s0);
    expect(s0.names).toEqual(["Ann", "Bo"]);
  });

  it("join to an unknown code → error no_room and close", async () => {
    const c = await connect("/join/ZZZZ-00");
    c.send(hello("Cy"));
    expect((await c.next("error")).code).toBe("no_room");
    await c.waitClosed();
  });

  it("bad code path → 400; plain GET on a socket route → 426", async () => {
    expect((await SELF_fetch("/join/nope")).status).toBe(400);
    expect((await SELF_fetch("/host", false)).status).toBe(426);
  });

  it("moves reach both players in order", async () => {
    const { host, guest, s0 } = await hostAndJoin();
    const first = s0.first === 0 ? host : guest;
    first.send({ t: "act", a: { type: 4, player: s0.first } });
    const m0 = await host.next("move");
    const m1 = await guest.next("move");
    expect(m0).toEqual(m1);
    expect(m0.seq).toBe(1);
  });

  it("an oversize message closes the socket", async () => {
    const { host } = await hostAndJoin();
    host.send(JSON.stringify({ t: "hash", seq: 1, d: "x".repeat(5000) }));
    expect(await host.waitClosed()).toBe(1008);
  });

  it("more than 20 messages in one second closes the socket", async () => {
    const { guest } = await hostAndJoin();
    for (let i = 0; i < 21; i++) guest.send({ t: "hash", seq: i, d: "a" });
    expect(await guest.waitClosed()).toBe(1008);
  });

  it("state survives eviction: a rejoining socket with the token gets the log", async () => {
    const { host, guest, s0, code, tokens } = await hostAndJoin();
    const first = s0.first === 0 ? host : guest;
    first.send({ t: "act", a: { type: 4, player: s0.first } });
    await host.next("move");
    guest.ws.close(1000);
    await host.next("opponent");
    await evictDurableObject(env.ROOM.get(env.ROOM.idFromName(code)));
    const again = await connect(`/join/${code}`);
    again.send(hello("Bo", { token: tokens[1] }));
    expect((await again.next("welcome")).seat).toBe(1);
    const start = await again.next("start");
    expect(start.log).toHaveLength(1);
  });
});

async function SELF_fetch(path: string, upgrade = true): Promise<Response> {
  const { SELF } = await import("cloudflare:test");
  return SELF.fetch(`http://relay${path}`, upgrade ? { headers: { Upgrade: "websocket" } } : {});
}
