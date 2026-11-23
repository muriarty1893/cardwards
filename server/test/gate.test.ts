import { describe, expect, it } from "vitest";
import { admit, GATE_LIMITS } from "../src/gate";
import { connect } from "./ws";
import { SELF } from "cloudflare:test";

const T = 1_700_000_000_000;

describe("admit", () => {
  it("allows 5 rooms a minute, then refuses until the minute has passed", () => {
    const times: number[] = [];
    for (let i = 0; i < GATE_LIMITS.perMinute; i++) expect(admit(times, T + i)).toBe(true);
    expect(admit(times, T + 10)).toBe(false);
    expect(admit(times, T + 60_000)).toBe(true);
  });
  it("allows 30 rooms an hour", () => {
    const times: number[] = [];
    let t = T;
    for (let i = 0; i < GATE_LIMITS.perHour; i++) {
      expect(admit(times, t)).toBe(true);
      t += 61_000 / GATE_LIMITS.perMinute + 1;
    }
    expect(admit(times, t)).toBe(false);
    expect(admit(times, T + 3_600_000)).toBe(true);
  });
  it("a refused try is not counted", () => {
    const times: number[] = [];
    for (let i = 0; i < 5; i++) admit(times, T);
    for (let i = 0; i < 10; i++) admit(times, T + 1);
    expect(times.length).toBe(5);
  });
});

describe("room creation limit", () => {
  it("refuses the 6th /host in a minute from one IP with a busy error", async () => {
    const ip = { "CF-Connecting-IP": "203.0.113.7" };
    for (let i = 0; i < 5; i++) {
      const r = await SELF.fetch("http://relay/host", { headers: { Upgrade: "websocket", ...ip } });
      expect(r.webSocket).toBeTruthy();
      r.webSocket!.accept();
      r.webSocket!.close();
    }
    const r = await SELF.fetch("http://relay/host", { headers: { Upgrade: "websocket", ...ip } });
    const ws = r.webSocket!;
    const got: unknown[] = [];
    ws.addEventListener("message", (e) => got.push(JSON.parse(e.data as string)));
    ws.accept();
    for (let i = 0; i < 100 && got.length === 0; i++) await new Promise((res) => setTimeout(res, 10));
    expect(got[0]).toMatchObject({ t: "error", code: "busy" });
  });
  it("other IPs are not affected", async () => {
    const c = await connect("/host");
    expect(c.ws).toBeTruthy();
    c.ws.close();
  });
});
