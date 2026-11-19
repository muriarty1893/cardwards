// The room's referee: seats, move numbering, the attack→block handshake and the timers.
// It knows nothing about the card rules; both games run those. Pure logic (no sockets, no storage)
// so it can be tested directly; the Room Durable Object wraps it.
import {
  ActionType,
  TIMES,
  actionDict,
  checkDeckShape,
  cleanName,
  type ActionDict,
  type ClientMsg,
  type DeckMsg,
  type ErrorCode,
  type HelloMsg,
  type OverReason,
  type Seat,
  type ServerMsg,
} from "./protocol";

export type Out = { to: Seat; msg: ServerMsg };
export type HelloResult = { seat: Seat | null; out: Out[]; error?: { code: ErrorCode; msg: string } };
export type SeatInfo = { name: string; deck: DeckMsg; token: string };
export type Pending = { seat: Seat; lane: number; target: number; hit: number };

export interface RoomState {
  code: string;
  quick: boolean;
  status: "claimed" | "waiting" | "playing" | "over";
  version: string | null;
  seats: [SeatInfo | null, SeatInfo | null];
  connected: [boolean, boolean];
  seed: number;
  first: Seat;
  active: Seat;
  log: ActionDict[];
  pending: Pending | null;
  hashes: Record<string, [string | null, string | null]>;
  results: [number | null, number | null];
  rematch: [boolean, boolean];
  over: { winner: number; reason: OverReason } | null;
  matchNo: number;
  createdAt: number;
  lastActiveAt: number;
  blockDeadline: number | null;
  reconnectDeadline: [number | null, number | null];
  cleanupAt: number | null;
}

const ERRORS: Record<ErrorCode, string> = {
  no_room: "No room with that code",
  full: "That room is full",
  version: "Different game version",
  over: "That match is over",
  bad_token: "That match can't be rejoined",
  bad_hello: "Bad hello",
};

const ACT_TYPES: number[] = [ActionType.PLAY_CARD, ActionType.BOOP, ActionType.CHOOSE, ActionType.END_TURN];

function other(seat: Seat): Seat {
  return (1 - seat) as Seat;
}

function both(msg: ServerMsg): Out[] {
  return [
    { to: 0, msg },
    { to: 1, msg },
  ];
}

export class Referee {
  constructor(
    public s: RoomState,
    private rand: () => number = Math.random,
  ) {}

  static fresh(code: string, quick: boolean, now: number): RoomState {
    return {
      code,
      quick,
      status: "claimed",
      version: null,
      seats: [null, null],
      connected: [false, false],
      seed: 0,
      first: 0,
      active: 0,
      log: [],
      pending: null,
      hashes: {},
      results: [null, null],
      rematch: [false, false],
      over: null,
      matchNo: 0,
      createdAt: now,
      lastActiveAt: now,
      blockDeadline: null,
      reconnectDeadline: [null, null],
      cleanupAt: now + TIMES.claimedMs,
    };
  }

  // --- Joining -----------------------------------------------------------------------------

  hello(role: "host" | "join", msg: HelloMsg, now: number): HelloResult {
    const s = this.s;
    if (msg.token !== undefined) return this.rejoin(msg, now);
    if (!checkDeckShape(msg.deck)) return this.fail("bad_hello");
    if (role === "host" && s.status === "claimed" && !s.quick) return this.seat0(msg, now);
    if (role === "join") {
      if (s.status === "claimed") return s.quick ? this.seat0(msg, now) : this.fail("no_room");
      if (s.status === "waiting") return msg.v === s.version ? this.seat1(msg, now) : this.fail("version");
      if (s.status === "playing") return this.fail("full");
      if (s.status === "over") return this.fail("over");
    }
    return this.fail("no_room");
  }

  private fail(code: ErrorCode): HelloResult {
    return { seat: null, out: [], error: { code, msg: ERRORS[code] } };
  }

  private newSeat(msg: HelloMsg): SeatInfo {
    return { name: cleanName(msg.name), deck: msg.deck as DeckMsg, token: crypto.randomUUID().replaceAll("-", "") };
  }

  private seat0(msg: HelloMsg, now: number): HelloResult {
    const s = this.s;
    s.seats[0] = this.newSeat(msg);
    s.version = msg.v;
    s.status = "waiting";
    s.connected[0] = true;
    s.cleanupAt = null;
    return {
      seat: 0,
      out: [
        { to: 0, msg: { t: "welcome", seat: 0, token: s.seats[0].token, code: s.code } },
        { to: 0, msg: { t: "waiting", code: s.code } },
      ],
    };
  }

  private seat1(msg: HelloMsg, now: number): HelloResult {
    const s = this.s;
    s.seats[1] = this.newSeat(msg);
    s.connected[1] = true;
    s.cleanupAt = null;
    const out: Out[] = [{ to: 1, msg: { t: "welcome", seat: 1, token: s.seats[1].token, code: s.code } }];
    this.begin(now);
    out.push(...both(this.startMsg()));
    return { seat: 1, out };
  }

  private rejoin(msg: HelloMsg, now: number): HelloResult {
    const s = this.s;
    const seat = ([0, 1] as Seat[]).find((i) => s.seats[i]?.token === msg.token);
    if (seat === undefined) return this.fail("bad_token");
    if (msg.v !== s.version) return this.fail("version");
    const info = s.seats[seat] as SeatInfo;
    s.connected[seat] = true;
    s.reconnectDeadline[seat] = null;
    s.cleanupAt = null;
    const out: Out[] = [{ to: seat, msg: { t: "welcome", seat, token: info.token, code: s.code } }];
    if (s.status === "waiting") {
      out.push({ to: seat, msg: { t: "waiting", code: s.code } });
    } else {
      out.push({ to: seat, msg: this.startMsg() });
      const p = s.pending;
      if (p && seat === p.seat) out.push({ to: seat, msg: { t: "blocking" } });
      if (p && seat !== p.seat) out.push({ to: seat, msg: { t: "block_wanted", lane: p.lane, target: p.target, hit: p.hit } });
      if (s.status === "playing") out.push({ to: other(seat), msg: { t: "opponent", status: "back" } });
    }
    return { seat, out };
  }

  /** A new match between the two seated players (first match or rematch). */
  private begin(now: number): void {
    const s = this.s;
    s.seed = 1 + Math.floor(this.rand() * 2147483646);
    s.first = this.rand() < 0.5 ? 0 : 1;
    s.active = s.first;
    s.status = "playing";
    s.log = [];
    s.pending = null;
    s.hashes = {};
    s.results = [null, null];
    s.rematch = [false, false];
    s.over = null;
    s.lastActiveAt = now;
    s.blockDeadline = null;
  }

  private startMsg(): ServerMsg {
    const s = this.s;
    return {
      t: "start",
      seed: s.seed,
      first: s.first,
      names: s.seats.map((x) => x?.name ?? ""),
      decks: s.seats.map((x) => x?.deck as DeckMsg),
      log: s.log,
      match: s.matchNo,
    };
  }

  // --- Messages from seated players -------------------------------------------------------

  message(seat: Seat, msg: ClientMsg, now: number): Out[] {
    const s = this.s;
    if (s.status === "playing" && seat === s.active) s.lastActiveAt = now;
    switch (msg.t) {
      case "act":
        return this.act(seat, msg.a, now);
      case "attack":
        return this.attack(seat, msg.lane, msg.target, msg.hit, now);
      case "block":
        return this.block(seat, msg.blocked, now);
      default:
        return [];
    }
  }

  private reject(seat: Seat, why: string): Out[] {
    return [{ to: seat, msg: { t: "rejected", why } }];
  }

  private act(seat: Seat, raw: Record<string, unknown>, now: number): Out[] {
    const s = this.s;
    if (s.status !== "playing") return this.reject(seat, "not playing");
    if (seat !== s.active) return this.reject(seat, "not your turn");
    if (s.pending) return this.reject(seat, "attack pending");
    const type = raw.type;
    if (typeof type !== "number" || !ACT_TYPES.includes(type)) return this.reject(seat, "bad move");
    const a = actionDict({ type, player: seat });
    for (const key of ["hand_index", "lane", "choice", "target_lane", "hit"] as const) {
      if (typeof raw[key] === "number") a[key] = raw[key] as number;
    }
    if (Array.isArray(raw.targets)) a.targets = raw.targets;
    if (typeof raw.blocked === "boolean") a.blocked = raw.blocked;
    return this.record(a, now);
  }

  private attack(seat: Seat, lane: number, target: number, hit: number, now: number): Out[] {
    const s = this.s;
    if (s.status !== "playing") return this.reject(seat, "not playing");
    if (seat !== s.active) return this.reject(seat, "not your turn");
    if (s.pending) return this.reject(seat, "attack pending");
    if (target < 0) return this.record(this.attackMove(seat, lane, target, hit, false), now);
    s.pending = { seat, lane, target, hit };
    s.blockDeadline = now + TIMES.blockMs;
    return [
      { to: other(seat), msg: { t: "block_wanted", lane, target, hit } },
      { to: seat, msg: { t: "blocking" } },
    ];
  }

  private block(seat: Seat, blocked: boolean, now: number): Out[] {
    const p = this.s.pending;
    if (!p || seat !== other(p.seat)) return [];
    return this.completeAttack(blocked, now);
  }

  private completeAttack(blocked: boolean, now: number): Out[] {
    const s = this.s;
    const p = s.pending as Pending;
    s.pending = null;
    s.blockDeadline = null;
    s.lastActiveAt = now;
    return this.record(this.attackMove(p.seat, p.lane, p.target, p.hit, blocked), now);
  }

  private attackMove(seat: Seat, lane: number, target: number, hit: number, blocked: boolean): ActionDict {
    return actionDict({ type: ActionType.ATTACK, player: seat, lane, target_lane: target, hit, blocked });
  }

  /** Append a move to the log and send it to both players. */
  private record(a: ActionDict, now: number, auto = false): Out[] {
    const s = this.s;
    s.log.push(a);
    if (a.type === ActionType.END_TURN) {
      s.active = other(s.active);
      s.lastActiveAt = now;
    }
    const msg: ServerMsg = auto ? { t: "move", seq: s.log.length, a, auto: true } : { t: "move", seq: s.log.length, a };
    return both(msg);
  }

  // --- Connections and time ---------------------------------------------------------------

  disconnect(seat: Seat, _now: number): Out[] {
    this.s.connected[seat] = false;
    return [];
  }

  tick(now: number): Out[] {
    const s = this.s;
    const out: Out[] = [];
    if (s.status === "playing" && s.pending && s.blockDeadline !== null && now >= s.blockDeadline) {
      out.push(...this.completeAttack(false, now));
    }
    const backstop = this.backstopAt();
    if (backstop !== null && now >= backstop) {
      out.push(...this.record(actionDict({ type: ActionType.END_TURN, player: s.active }), now, true));
    }
    return out;
  }

  /** When the room ends the active player's turn for them (frozen tab, dropped player). */
  private backstopAt(): number | null {
    const s = this.s;
    return s.status === "playing" && !s.pending ? s.lastActiveAt + TIMES.backstopMs : null;
  }

  nextDeadline(): number | null {
    const s = this.s;
    const times = [s.pending ? s.blockDeadline : null, this.backstopAt(), ...s.reconnectDeadline, s.cleanupAt];
    const set = times.filter((t): t is number => t !== null);
    return set.length ? Math.min(...set) : null;
  }

  dead(now: number): boolean {
    return this.s.cleanupAt !== null && now >= this.s.cleanupAt;
  }
}
