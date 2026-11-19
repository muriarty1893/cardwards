import { describe, expect, it } from "vitest";
import { connect } from "./ws";

describe("quick match lobby", () => {
  it("two sockets with the same version are matched to the same new room", async () => {
    const a = await connect("/queue?v=n1-same");
    const b = await connect("/queue?v=n1-same");
    const ma = await a.next("matched");
    const mb = await b.next("matched");
    expect(ma.code).toBe(mb.code);
    expect(ma.code).toMatch(/^[A-Z]{3,5}-[0-9]{2}$/);
    const p1 = await connect(`/join/${ma.code}`);
    p1.send({ t: "hello", v: "n1-same", name: "A", deck: { name: "d", lands: [0, 0, 0, 0], cards: Array(30).fill("x") } });
    expect((await p1.next("welcome")).seat).toBe(0);
  });

  it("matched sockets stay open for the client to close and are never matched again", async () => {
    const a = await connect("/queue?v=n1-again");
    const b = await connect("/queue?v=n1-again");
    await a.next("matched");
    await b.next("matched");
    const c = await connect("/queue?v=n1-again");
    await new Promise((r) => setTimeout(r, 200));
    expect(b.closed).toBeNull();
    expect(c.msgs).toEqual([]);
    for (const x of [a, b, c]) x.ws.close(1000);
  });

  it("different versions are not matched", async () => {
    const a = await connect("/queue?v=n1-aaa");
    const b = await connect("/queue?v=n1-bbb");
    await new Promise((r) => setTimeout(r, 200));
    expect(a.msgs).toEqual([]);
    expect(b.msgs).toEqual([]);
    a.ws.close(1000);
    b.ws.close(1000);
  });

  it("a queue socket without a version is refused", async () => {
    const { SELF } = await import("cloudflare:test");
    const r = await SELF.fetch("http://relay/queue", { headers: { Upgrade: "websocket" } });
    expect(r.status).toBe(400);
  });
});
