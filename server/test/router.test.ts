import { SELF } from "cloudflare:test";
import { describe, expect, it } from "vitest";

describe("router", () => {
  it("answers /health", async () => {
    const r = await SELF.fetch("http://x/health");
    expect(r.status).toBe(200);
    expect(await r.text()).toBe("ok");
  });
  it("404s unknown paths", async () => {
    expect((await SELF.fetch("http://x/nope")).status).toBe(404);
  });
});
