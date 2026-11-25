import { describe, expect, it } from "vitest";
import { LIMITS, actionDict, checkDeckShape, cleanName, parseClient } from "../src/protocol";

describe("protocol", () => {
  it("cleans names", () => {
    expect(cleanName("  Bo\u0007b  ")).toBe("Bob");
    expect(cleanName("x".repeat(40))).toHaveLength(16);
    expect(cleanName("")).toBe("Dreamer");
    expect(cleanName("   ")).toBe("Dreamer");
    expect(cleanName(42)).toBe("Dreamer");
    expect(cleanName("Zoë 🌙")).toBe("Zoë 🌙");
  });

  it("parses only known, well-typed, small messages", () => {
    expect(parseClient('{"t":"block","blocked":true}')).toEqual({ t: "block", blocked: true });
    expect(parseClient('{"t":"block","blocked":"yes"}')).toBeNull();
    expect(parseClient('{"t":"nope"}')).toBeNull();
    expect(parseClient("not json")).toBeNull();
    expect(parseClient("[1,2]")).toBeNull();
    expect(parseClient(JSON.stringify({ t: "hash", seq: 1, d: "x".repeat(5000) }))).toBeNull();
    expect(parseClient('{"t":"hash","seq":3,"d":"abc"}')).toEqual({ t: "hash", seq: 3, d: "abc" });
    expect(parseClient('{"t":"attack","lane":1,"target":-1,"hit":2}')).toEqual({ t: "attack", lane: 1, target: -1, hit: 2 });
    expect(parseClient('{"t":"attack","lane":7,"target":-1,"hit":2}')).toBeNull();
    expect(parseClient('{"t":"act","a":{"type":4}}')).toMatchObject({ t: "act" });
    expect(parseClient('{"t":"act","a":"x"}')).toBeNull();
    expect(parseClient('{"t":"result","winner":1}')).toEqual({ t: "result", winner: 1 });
    expect(parseClient('{"t":"concede"}')).toEqual({ t: "concede" });
  });

  it("checks deck shape", () => {
    const ok = { name: "Mine", lands: [0, 0, 1, 0], cards: Array(30).fill("mossback") };
    expect(checkDeckShape(ok)).toBe(true);
    expect(checkDeckShape({ ...ok, cards: ok.cards.slice(1) })).toBe(false);
    expect(checkDeckShape({ ...ok, lands: [0, 0, 9, 0] })).toBe(false);
    expect(checkDeckShape({ ...ok, lands: [5, 5, 3, 5] })).toBe(true); // Sunny Dunes
    expect(checkDeckShape({ ...ok, lands: [6, 0, 0, 0] })).toBe(false);
    expect(checkDeckShape({ ...ok, cards: Array(40).fill("mossback") })).toBe(true); // 40-card decks
    expect(checkDeckShape({ ...ok, cards: Array(35).fill("mossback") })).toBe(false);
    expect(checkDeckShape({ ...ok, name: "x".repeat(LIMITS.deckNameMax + 1) })).toBe(false);
    expect(checkDeckShape({ ...ok, cards: [...ok.cards.slice(1), 3] })).toBe(false);
    expect(checkDeckShape(null)).toBe(false);
  });

  it("fills action defaults like Action.to_dict", () => {
    expect(actionDict({ type: 4, player: 1 })).toEqual({
      type: 4, player: 1, hand_index: -1, lane: -1, targets: [], hit: 0, blocked: false, choice: -1, target_lane: -1,
    });
  });
});
