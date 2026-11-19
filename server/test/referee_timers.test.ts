import { describe, expect, it } from "vitest";
import { TIMES } from "../src/protocol";
import { T0, endTurn, hello, ofType, started, to } from "./helpers";

const START = T0 + 1000; // when started() seats the second player

describe("referee: attacks and blocks", () => {
  it("hero attack is numbered at once with blocked false", () => {
    const { ref, first } = started();
    const out = ref.message(first, { t: "attack", lane: 2, target: -1, hit: 1 }, START + 10);
    const mv = ofType(to(out, 0), "move")[0];
    expect(mv.a).toMatchObject({ type: 2, player: first, lane: 2, target_lane: -1, hit: 1, blocked: false });
    expect(to(out, 1)).toEqual(to(out, 0));
    expect(ref.s.pending).toBeNull();
  });

  it("creature attack: defender gets block_wanted, attacker blocking; block completes the move", () => {
    const { ref, first } = started();
    const def = (1 - first) as 0 | 1;
    const out = ref.message(first, { t: "attack", lane: 0, target: 3, hit: 2 }, START + 10);
    expect(to(out, def)).toEqual([{ t: "block_wanted", lane: 0, target: 3, hit: 2 }]);
    expect(to(out, first)).toEqual([{ t: "blocking" }]);
    expect(ref.s.log).toHaveLength(0);
    const done = ref.message(def, { t: "block", blocked: true }, START + 900);
    const mv = ofType(to(done, first), "move")[0];
    expect(mv.a).toMatchObject({ type: 2, player: first, lane: 0, target_lane: 3, hit: 2, blocked: true });
    expect(to(done, def)).toEqual(to(done, first));
    expect(ref.s.pending).toBeNull();
    expect(ref.s.blockDeadline).toBeNull();
  });

  it("a block from the attacker is ignored; a second attack while pending is rejected", () => {
    const { ref, first } = started();
    ref.message(first, { t: "attack", lane: 0, target: 3, hit: 0 }, START + 10);
    expect(ref.message(first, { t: "block", blocked: true }, START + 20)).toEqual([]);
    const again = ref.message(first, { t: "attack", lane: 1, target: 2, hit: 0 }, START + 30);
    expect(ofType(to(again, first), "rejected")).toHaveLength(1);
    expect(ofType(to(ref.message(first, endTurn(first), START + 40), first), "rejected")).toHaveLength(1);
    expect(ref.s.log).toHaveLength(0);
  });

  it("attack from the waiting seat → rejected", () => {
    const { ref, first } = started();
    const def = (1 - first) as 0 | 1;
    expect(ofType(to(ref.message(def, { t: "attack", lane: 0, target: -1, hit: 0 }, START), def), "rejected")).toHaveLength(1);
  });

  it("no block within 10 s → move with blocked false", () => {
    const { ref, first } = started();
    ref.message(first, { t: "attack", lane: 1, target: 1, hit: 0 }, START + 10);
    expect(ref.nextDeadline()).toBe(START + 10 + TIMES.blockMs);
    expect(ref.tick(START + 10 + TIMES.blockMs - 1)).toEqual([]);
    const out = ref.tick(START + 10 + TIMES.blockMs);
    expect(ofType(to(out, first), "move")[0].a).toMatchObject({ type: 2, blocked: false, target_lane: 1 });
    expect(ref.s.pending).toBeNull();
  });
});

describe("referee: turn backstop", () => {
  it("70 s silence from the active seat → auto END_TURN; 69 s → nothing", () => {
    const { ref, first } = started();
    expect(ref.tick(START + TIMES.backstopMs - 1000)).toEqual([]);
    const out = ref.tick(START + TIMES.backstopMs);
    const mv = ofType(to(out, 0), "move")[0];
    expect(mv).toMatchObject({ seq: 1, auto: true });
    expect(mv.a).toMatchObject({ type: 4, player: first });
    expect(ref.s.active).toBe(1 - first);
  });

  it("any message from the active seat restarts the backstop", () => {
    const { ref, first } = started();
    ref.message(first, { t: "hash", seq: 0, d: "x" }, START + 60_000);
    expect(ref.tick(START + TIMES.backstopMs)).toEqual([]);
    expect(ref.nextDeadline()).toBe(START + 60_000 + TIMES.backstopMs);
  });

  it("no backstop while an attack is pending", () => {
    const { ref, first } = started();
    ref.message(first, { t: "attack", lane: 1, target: 1, hit: 0 }, START + 10);
    ref.s.blockDeadline = null; // pretend the block timer never fires
    expect(ref.tick(START + 10 + TIMES.backstopMs * 2)).toEqual([]);
  });

  it("backstop END_TURN, then the late act from that seat → rejected, log unchanged", () => {
    const { ref, first } = started();
    ref.tick(START + TIMES.backstopMs);
    const late = ref.message(first, { t: "act", a: { type: 0, player: first, hand_index: 0, lane: 0 } }, START + TIMES.backstopMs + 50);
    expect(late).toEqual([{ to: first, msg: { t: "rejected", why: "not your turn" } }]);
    expect(ref.s.log).toHaveLength(1);
  });
});

describe("referee: rejoin during a pending attack", () => {
  it("defender rejoins → start then block_wanted", () => {
    const { ref, tokens, first } = started();
    const def = (1 - first) as 0 | 1;
    ref.message(first, { t: "attack", lane: 0, target: 2, hit: 1 }, START + 10);
    ref.disconnect(def, START + 20);
    const r = ref.hello("join", hello("x", { token: tokens[def] }), START + 30);
    expect(to(r.out, def).map((m) => m.t)).toEqual(["welcome", "start", "block_wanted"]);
    expect(ofType(to(r.out, def), "block_wanted")[0]).toEqual({ t: "block_wanted", lane: 0, target: 2, hit: 1 });
  });

  it("attacker rejoins → start then blocking", () => {
    const { ref, tokens, first } = started();
    ref.message(first, { t: "attack", lane: 0, target: 2, hit: 1 }, START + 10);
    ref.disconnect(first, START + 20);
    const r = ref.hello("join", hello("x", { token: tokens[first] }), START + 30);
    expect(to(r.out, first).map((m) => m.t)).toEqual(["welcome", "start", "blocking"]);
  });
});

describe("referee: deadlines", () => {
  it("nextDeadline is the earliest of block, backstop, reconnect and cleanup", () => {
    const { ref, first } = started();
    expect(ref.nextDeadline()).toBe(START + TIMES.backstopMs);
    ref.message(first, { t: "attack", lane: 0, target: 0, hit: 0 }, START + 100);
    expect(ref.nextDeadline()).toBe(START + 100 + TIMES.blockMs);
    ref.s.reconnectDeadline[0] = START + 50;
    expect(ref.nextDeadline()).toBe(START + 50);
  });
});
