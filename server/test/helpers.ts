import type { ClientMsg, DeckMsg, HelloMsg, ServerMsg } from "../src/protocol";
import { Referee, type Out } from "../src/referee";

export const VERSION = "n1-test";
export const T0 = 1_700_000_000_000;

export function seeded(seed = 1): () => number {
  let s = seed >>> 0;
  return () => {
    s = (Math.imul(s, 1664525) + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

export function deck(name = "Mine"): DeckMsg {
  return { name, lands: [0, 0, 1, 0], cards: Array(30).fill("mossback") };
}

export function hello(name: string, extra: Partial<HelloMsg> = {}): HelloMsg {
  return { t: "hello", v: VERSION, name, deck: deck(name + "'s deck"), ...extra };
}

export function to(out: Out[], seat: 0 | 1): ServerMsg[] {
  return out.filter((o) => o.to === seat).map((o) => o.msg);
}

export function ofType<T extends ServerMsg["t"]>(msgs: ServerMsg[], t: T): Extract<ServerMsg, { t: T }>[] {
  return msgs.filter((m) => m.t === t) as Extract<ServerMsg, { t: T }>[];
}

/** A room where Ann hosted and Bo joined; returns the referee and both tokens. */
export function started(seed = 7): { ref: Referee; tokens: [string, string]; first: 0 | 1 } {
  const ref = new Referee(Referee.fresh("FROG-42", false, T0), seeded(seed));
  const a = ref.hello("host", hello("Ann"), T0);
  const b = ref.hello("join", hello("Bo"), T0 + 1000);
  const ta = ofType(to(a.out, 0), "welcome")[0].token;
  const tb = ofType(to(b.out, 1), "welcome")[0].token;
  return { ref, tokens: [ta, tb], first: ref.s.first };
}

export function endTurn(seat: 0 | 1): ClientMsg {
  return { t: "act", a: { type: 4, player: seat } };
}
