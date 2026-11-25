import { describe, expect, it } from "vitest";
import { Referee } from "../src/referee";
import { T0, VERSION, deck, endTurn, hello, ofType, seeded, started, to } from "./helpers";

describe("referee: seats and start", () => {
  it("host then join starts with the same seed/first/names/decks for both seats", () => {
    const ref = new Referee(Referee.fresh("FROG-42", false, T0), seeded(3));
    const a = ref.hello("host", hello("Ann"), T0);
    expect(a.seat).toBe(0);
    expect(ofType(to(a.out, 0), "welcome")[0]).toMatchObject({ seat: 0, code: "FROG-42" });
    expect(ofType(to(a.out, 0), "waiting")).toEqual([{ t: "waiting", code: "FROG-42" }]);
    const b = ref.hello("join", hello("Bo"), T0 + 5);
    expect(b.seat).toBe(1);
    const s0 = ofType(to(b.out, 0), "start");
    const s1 = ofType(to(b.out, 1), "start");
    expect(s0).toHaveLength(1);
    expect(s1).toEqual(s0);
    expect(s0[0].names).toEqual(["Ann", "Bo"]);
    expect(s0[0].decks.map((d) => d.name)).toEqual(["Ann's deck", "Bo's deck"]);
    expect(s0[0].log).toEqual([]);
    expect(s0[0].match).toBe(0);
    expect(Number.isInteger(s0[0].seed) && s0[0].seed > 0 && s0[0].seed < 2 ** 31).toBe(true);
    expect([0, 1]).toContain(s0[0].first);
    expect(ref.s.status).toBe("playing");
    expect(ref.s.active).toBe(s0[0].first);
    const tokens = [ofType(to(a.out, 0), "welcome")[0].token, ofType(to(b.out, 1), "welcome")[0].token];
    expect(tokens[0]).not.toBe(tokens[1]);
    expect(tokens[0].length).toBeGreaterThanOrEqual(16);
  });

  it("join with another version → error version, close", () => {
    const ref = new Referee(Referee.fresh("FROG-42", false, T0), seeded());
    ref.hello("host", hello("Ann"), T0);
    const b = ref.hello("join", hello("Bo", { v: "n1-other" }), T0);
    expect(b.seat).toBeNull();
    expect(b.error?.code).toBe("version");
    expect(ref.s.status).toBe("waiting");
  });

  it("third joiner → error full; wrong token → bad_token; bad deck → bad_hello", () => {
    const { ref } = started();
    expect(ref.hello("join", hello("Cy"), T0).error?.code).toBe("full");
    expect(ref.hello("join", hello("Cy", { token: "nope" }), T0).error?.code).toBe("bad_token");
    const fresh = new Referee(Referee.fresh("FROG-43", false, T0), seeded());
    expect(fresh.hello("host", hello("Ann", { deck: { name: "x", lands: [0], cards: [] } }), T0).error?.code).toBe("bad_hello");
  });

  it("joining a room nobody hosted yet → no_room; a quick room seats its first joiner", () => {
    const hosted = new Referee(Referee.fresh("FROG-44", false, T0), seeded());
    expect(hosted.hello("join", hello("Bo"), T0).error?.code).toBe("no_room");
    const quick = new Referee(Referee.fresh("FROG-45", true, T0), seeded());
    expect(quick.hello("join", hello("Ann"), T0).seat).toBe(0);
    expect(quick.hello("join", hello("Bo"), T0).seat).toBe(1);
    expect(quick.s.status).toBe("playing");
  });

  it("names are cleaned", () => {
    const ref = new Referee(Referee.fresh("FROG-42", false, T0), seeded());
    ref.hello("host", hello("  \u0007" + "A".repeat(30), { deck: deck() }), T0);
    expect(ref.s.seats[0]?.name).toBe("A".repeat(16));
    expect(ref.s.version).toBe(VERSION);
  });
});

describe("referee: moves", () => {
  it("numbers moves from 1, sends them to both; END_TURN flips active", () => {
    const { ref, first } = started();
    const other = (1 - first) as 0 | 1;
    const out = ref.message(first, { t: "act", a: { type: 0, player: 9, hand_index: 2, lane: 1, targets: [] } }, T0 + 2000);
    expect(to(out, 0)).toEqual(to(out, 1));
    const mv = ofType(to(out, 0), "move")[0];
    expect(mv.seq).toBe(1);
    expect(mv.a).toMatchObject({ type: 0, player: first, hand_index: 2, lane: 1 });
    expect(mv.auto).toBeUndefined();
    const out2 = ref.message(first, endTurn(first), T0 + 3000);
    expect(ofType(to(out2, 1), "move")[0].seq).toBe(2);
    expect(ref.s.active).toBe(other);
    expect(ref.s.log).toHaveLength(2);
  });

  it("a choice from the waiting seat is recorded (Dark Gift offered in the rival's turn)", () => {
    const { ref, first } = started();
    const other = (1 - first) as 0 | 1;
    const out = ref.message(other, { t: "act", a: { type: 3, player: other, choice: 1 } }, T0 + 2000);
    const mv = ofType(to(out, first), "move")[0];
    expect(mv.a).toMatchObject({ type: 3, player: other, choice: 1 });
    expect(ref.s.active).toBe(first);
  });

  it("act from the waiting seat → rejected to sender only, no move", () => {
    const { ref, first } = started();
    const other = (1 - first) as 0 | 1;
    const out = ref.message(other, endTurn(other), T0 + 2000);
    expect(out).toEqual([{ to: other, msg: { t: "rejected", why: "not your turn" } }]);
    expect(ref.s.log).toHaveLength(0);
  });

  it("act claiming the ATTACK type → rejected (attacks use attack)", () => {
    const { ref, first } = started();
    const out = ref.message(first, { t: "act", a: { type: 2, player: first, lane: 0, target_lane: -1 } }, T0 + 2000);
    expect(ofType(to(out, first), "rejected")).toHaveLength(1);
    expect(ref.s.log).toHaveLength(0);
  });

  it("act before the match started → rejected", () => {
    const ref = new Referee(Referee.fresh("FROG-42", false, T0), seeded());
    ref.hello("host", hello("Ann"), T0);
    const out = ref.message(0, endTurn(0), T0);
    expect(ofType(to(out, 0), "rejected")).toHaveLength(1);
  });

  it("rejoin with token gets its seat and start with the full log", () => {
    const { ref, tokens, first } = started();
    ref.message(first, endTurn(first), T0 + 2000);
    const other = (1 - first) as 0 | 1;
    ref.disconnect(other, T0 + 2500);
    const r = ref.hello("join", hello("Whoever", { token: tokens[other] }), T0 + 3000);
    expect(r.seat).toBe(other);
    const start = ofType(to(r.out, other), "start")[0];
    expect(start.log).toHaveLength(1);
    expect(start.names).toEqual(["Ann", "Bo"]);
    expect(ofType(to(r.out, first), "opponent")).toEqual([{ t: "opponent", status: "back" }]);
  });
});
