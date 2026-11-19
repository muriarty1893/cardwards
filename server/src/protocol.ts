// Messages between the Dream Isles game and the relay (spec section 4), and their limits.

export const LIMITS = { maxBytes: 4096, perSecond: 20, nameMax: 16, deckNameMax: 24, deckSize: 30 } as const;

export const TIMES = {
  blockMs: 10_000,
  backstopMs: 70_000,
  reconnectMs: 60_000,
  claimedMs: 120_000,
  overMs: 600_000,
  emptyMs: 600_000,
} as const;

/** Action.Type in core/action.gd. */
export const ActionType = { PLAY_CARD: 0, BOOP: 1, ATTACK: 2, CHOOSE: 3, END_TURN: 4 } as const;

/** Action.to_dict() in core/action.gd. */
export type ActionDict = {
  type: number;
  player: number;
  hand_index: number;
  lane: number;
  targets: unknown[];
  hit: number;
  blocked: boolean;
  choice: number;
  target_lane: number;
};

export type DeckMsg = { name: string; lands: number[]; cards: string[] };
export type Seat = 0 | 1;
export type OverReason = "normal" | "concede" | "forfeit" | "desync";
export type ErrorCode = "no_room" | "full" | "version" | "over" | "bad_token" | "bad_hello";

export type HelloMsg = { t: "hello"; v: string; name: unknown; deck: unknown; token?: string };
export type ClientMsg =
  | HelloMsg
  | { t: "act"; a: Record<string, unknown> }
  | { t: "attack"; lane: number; target: number; hit: number }
  | { t: "block"; blocked: boolean }
  | { t: "hash"; seq: number; d: string }
  | { t: "result"; winner: number }
  | { t: "desync"; seq: number; why: string }
  | { t: "concede" }
  | { t: "rematch" };

export type ServerMsg =
  | { t: "welcome"; seat: Seat; token: string; code: string }
  | { t: "waiting"; code: string }
  | { t: "start"; seed: number; first: Seat; names: string[]; decks: DeckMsg[]; log: ActionDict[]; match: number }
  | { t: "move"; seq: number; a: ActionDict; auto?: true }
  | { t: "block_wanted"; lane: number; target: number; hit: number }
  | { t: "blocking" }
  | { t: "rejected"; why: string }
  | { t: "opponent"; status: "away" | "back" | "left"; until?: number }
  | { t: "rematch_wanted" }
  | { t: "over"; winner: number; reason: OverReason }
  | { t: "error"; code: ErrorCode; msg: string }
  | { t: "matched"; code: string };

const encoder = new TextEncoder();

export function byteLength(raw: string): number {
  return encoder.encode(raw).length;
}

function isInt(v: unknown, lo: number, hi: number): v is number {
  return typeof v === "number" && Number.isInteger(v) && v >= lo && v <= hi;
}

function isObject(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

function shortString(v: unknown, max: number): v is string {
  return typeof v === "string" && v.length <= max;
}

/** A well-formed client message, or null (unknown type, wrong field types, too big, not JSON). */
export function parseClient(raw: string): ClientMsg | null {
  if (byteLength(raw) > LIMITS.maxBytes) return null;
  let m: unknown;
  try {
    m = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!isObject(m)) return null;
  switch (m.t) {
    case "hello":
      if (!shortString(m.v, 32)) return null;
      if (m.token !== undefined && !shortString(m.token, 64)) return null;
      return { t: "hello", v: m.v, name: m.name, deck: m.deck, ...(m.token !== undefined ? { token: m.token as string } : {}) };
    case "act":
      return isObject(m.a) ? { t: "act", a: m.a } : null;
    case "attack":
      return isInt(m.lane, 0, 3) && isInt(m.target, -1, 3) && isInt(m.hit, 0, 2)
        ? { t: "attack", lane: m.lane, target: m.target, hit: m.hit }
        : null;
    case "block":
      return typeof m.blocked === "boolean" ? { t: "block", blocked: m.blocked } : null;
    case "hash":
      return isInt(m.seq, 0, 1e9) && shortString(m.d, 64) ? { t: "hash", seq: m.seq, d: m.d } : null;
    case "result":
      return isInt(m.winner, 0, 1) ? { t: "result", winner: m.winner } : null;
    case "desync":
      return isInt(m.seq, 0, 1e9) ? { t: "desync", seq: m.seq, why: shortString(m.why, 200) ? m.why : "" } : null;
    case "concede":
      return { t: "concede" };
    case "rematch":
      return { t: "rematch" };
    default:
      return null;
  }
}

/** Trimmed, control characters removed, at most 16 characters; "Dreamer" when nothing is left. */
export function cleanName(s: unknown): string {
  if (typeof s !== "string") return "Dreamer";
  const cleaned = Array.from(s.replace(/\p{Cc}/gu, "").trim()).slice(0, LIMITS.nameMax).join("").trim();
  return cleaned === "" ? "Dreamer" : cleaned;
}

/** The deck's shape only; the games check the cards themselves. */
export function checkDeckShape(d: unknown): d is DeckMsg {
  if (!isObject(d)) return false;
  if (!shortString(d.name, LIMITS.deckNameMax)) return false;
  if (!Array.isArray(d.lands) || d.lands.length !== 4 || !d.lands.every((l) => isInt(l, 0, 4))) return false;
  return (
    Array.isArray(d.cards) &&
    d.cards.length === LIMITS.deckSize &&
    d.cards.every((c) => typeof c === "string" && c.length > 0 && c.length <= 40)
  );
}

export function actionDict(partial: Partial<ActionDict> & { type: number; player: number }): ActionDict {
  return {
    hand_index: -1,
    lane: -1,
    targets: [],
    hit: 0,
    blocked: false,
    choice: -1,
    target_lane: -1,
    ...partial,
  };
}
