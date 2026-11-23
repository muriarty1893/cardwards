// Room creation limit: one Gate object per client IP counts the rooms it opened recently
// (/host and quick match both count). Kept in memory: an evicted Gate simply starts counting again.
import { DurableObject } from "cloudflare:workers";
import type { Env } from "./claim";

export const GATE_LIMITS = { perMinute: 5, perHour: 30 } as const;
const MINUTE = 60_000;
const HOUR = 3_600_000;

/** True when one more room fits under both windows; records it if so. `times` is trimmed in place. */
export function admit(times: number[], now: number): boolean {
  while (times.length > 0 && now - times[0] >= HOUR) times.shift();
  const lastMinute = times.filter((t) => now - t < MINUTE).length;
  if (lastMinute >= GATE_LIMITS.perMinute || times.length >= GATE_LIMITS.perHour) return false;
  times.push(now);
  return true;
}

export class Gate extends DurableObject<Env> {
  private times: number[] = [];

  async allow(now: number = Date.now()): Promise<boolean> {
    return admit(this.times, now);
  }
}

/** The caller's IP as Cloudflare reports it; null without one (tests and wrangler dev are not limited). */
export function clientIp(request: Request): string | null {
  return request.headers.get("CF-Connecting-IP");
}
