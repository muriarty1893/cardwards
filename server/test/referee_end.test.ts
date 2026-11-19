import { describe, expect, it } from "vitest";
import { TIMES } from "../src/protocol";
import { Referee } from "../src/referee";
import { T0, endTurn, hello, ofType, seeded, started, to } from "./helpers";

const START = T0 + 1000;

function endNormally(ref: Referee, winner: number, now = START + 5000): void {
  ref.message(0, { t: "result", winner }, now);
  ref.message(1, { t: "result", winner }, now);
}

describe("referee: checksums and results", () => {
  it("different hashes for the same seq → over desync to both; equal → nothing", () => {
    const { ref, first } = started();
    ref.message(first, endTurn(first), START + 10);
    expect(ref.message(0, { t: "hash", seq: 1, d: "aaa" }, START + 20)).toEqual([]);
    expect(ref.message(1, { t: "hash", seq: 1, d: "aaa" }, START + 21)).toEqual([]);
    ref.message(1 - first as 0 | 1, endTurn((1 - first) as 0 | 1), START + 30);
    ref.message(0, { t: "hash", seq: 2, d: "bbb" }, START + 40);
    const out = ref.message(1, { t: "hash", seq: 2, d: "ccc" }, START + 41);
    expect(to(out, 0)).toEqual([{ t: "over", winner: -1, reason: "desync" }]);
    expect(to(out, 1)).toEqual(to(out, 0));
    expect(ref.s.status).toBe("over");
  });

  it("keeps only the last 8 checksums", () => {
    const { ref } = started();
    for (let i = 1; i <= 20; i++) ref.message(0, { t: "hash", seq: i, d: "x" }, START + i);
    expect(Object.keys(ref.s.hashes).length).toBeLessThanOrEqual(8);
  });

  it("a desync report ends the match with no winner", () => {
    const { ref } = started();
    const out = ref.message(1, { t: "desync", seq: 3, why: "bad move" }, START + 10);
    expect(to(out, 0)).toEqual([{ t: "over", winner: -1, reason: "desync" }]);
  });

  it("matching results → over normal; different results → desync", () => {
    const a = started();
    a.ref.message(0, { t: "result", winner: 1 }, START + 10);
    const out = a.ref.message(1, { t: "result", winner: 1 }, START + 11);
    expect(to(out, 0)).toEqual([{ t: "over", winner: 1, reason: "normal" }]);
    const b = started(9);
    b.ref.message(0, { t: "result", winner: 1 }, START + 10);
    expect(to(b.ref.message(1, { t: "result", winner: 0 }, START + 11), 1)).toEqual([{ t: "over", winner: -1, reason: "desync" }]);
  });

  it("concede → over concede, the rival wins", () => {
    const { ref } = started();
    const out = ref.message(1, { t: "concede" }, START + 10);
    expect(to(out, 0)).toEqual([{ t: "over", winner: 0, reason: "concede" }]);
    expect(to(out, 1)).toEqual([{ t: "over", winner: 0, reason: "concede" }]);
  });

  it("moves after the end are rejected", () => {
    const { ref, first } = started();
    endNormally(ref, 0);
    expect(ofType(to(ref.message(first, endTurn(first), START + 6000), first), "rejected")).toHaveLength(1);
  });
});

describe("referee: rematch", () => {
  it("rematch from both after a normal end → a new start with match 1, new seed, empty log", () => {
    const { ref, first } = started();
    ref.message(first, endTurn(first), START + 10);
    const oldSeed = ref.s.seed;
    endNormally(ref, 0);
    const one = ref.message(0, { t: "rematch" }, START + 6000);
    expect(to(one, 1)).toEqual([{ t: "rematch_wanted" }]);
    expect(to(one, 0)).toEqual([]);
    const two = ref.message(1, { t: "rematch" }, START + 7000);
    const s0 = ofType(to(two, 0), "start")[0];
    expect(s0.match).toBe(1);
    expect(s0.log).toEqual([]);
    expect(s0.seed).not.toBe(oldSeed);
    expect(to(two, 1)).toEqual(to(two, 0));
    expect(ref.s.status).toBe("playing");
    expect(ref.s.cleanupAt).toBeNull();
  });

  it("rematch after a desync → rejected", () => {
    const { ref } = started();
    ref.message(1, { t: "desync", seq: 0, why: "" }, START + 10);
    expect(ref.message(0, { t: "rematch" }, START + 20)).toEqual([{ to: 0, msg: { t: "rejected", why: "no rematch" } }]);
  });

  it("rematch after the rival left → rejected with why left; the rival hears opponent left", () => {
    const { ref } = started();
    endNormally(ref, 1);
    const gone = ref.disconnect(1, START + 6000);
    expect(to(gone, 0)).toEqual([{ t: "opponent", status: "left" }]);
    expect(ref.message(0, { t: "rematch" }, START + 6100)).toEqual([{ to: 0, msg: { t: "rejected", why: "left" } }]);
  });
});

describe("referee: disconnects and cleanup", () => {
  it("drop during play → opponent away until +60 s; rejoin → back; no rejoin for 60 s → forfeit", () => {
    const { ref, tokens } = started();
    const away = ref.disconnect(1, START + 100);
    expect(to(away, 0)).toEqual([{ t: "opponent", status: "away", until: START + 100 + TIMES.reconnectMs }]);
    expect(ref.nextDeadline()).toBe(START + 100 + TIMES.reconnectMs);
    const back = ref.hello("join", hello("Bo", { token: tokens[1] }), START + 200);
    expect(ofType(to(back.out, 0), "opponent")).toEqual([{ t: "opponent", status: "back" }]);
    ref.disconnect(1, START + 300);
    expect(ref.tick(START + 300 + TIMES.reconnectMs - 1).filter((o) => o.msg.t === "over")).toEqual([]);
    const out = ref.tick(START + 300 + TIMES.reconnectMs);
    expect(ofType(to(out, 0), "over")).toEqual([{ t: "over", winner: 0, reason: "forfeit" }]);
  });

  it("rejoining a finished match gets start and over", () => {
    const { ref, tokens } = started();
    endNormally(ref, 1);
    ref.disconnect(0, START + 6000);
    const r = ref.hello("join", hello("Ann", { token: tokens[0] }), START + 6100);
    expect(to(r.out, 0).map((m) => m.t)).toEqual(["welcome", "start", "over"]);
  });

  it("a claimed room nobody joins is dead after 2 min", () => {
    const ref = new Referee(Referee.fresh("FROG-42", false, T0), seeded());
    expect(ref.dead(T0 + TIMES.claimedMs - 1)).toBe(false);
    expect(ref.dead(T0 + TIMES.claimedMs)).toBe(true);
  });

  it("a finished room is dead 10 min after the end", () => {
    const { ref } = started();
    endNormally(ref, 0, START + 5000);
    expect(ref.dead(START + 5000 + TIMES.overMs - 1)).toBe(false);
    expect(ref.dead(START + 5000 + TIMES.overMs)).toBe(true);
  });

  it("a room with nobody connected is dead after 10 min", () => {
    const ref = new Referee(Referee.fresh("FROG-42", false, T0), seeded());
    ref.hello("host", hello("Ann"), T0);
    ref.disconnect(0, T0 + 50);
    expect(ref.dead(T0 + 50 + TIMES.emptyMs - 1)).toBe(false);
    expect(ref.dead(T0 + 50 + TIMES.emptyMs)).toBe(true);
  });
});
