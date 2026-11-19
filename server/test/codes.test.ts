import { describe, expect, it } from "vitest";
import { WORDS, isCode, makeCode } from "../src/codes";

describe("room codes", () => {
  it("makes valid codes", () => {
    for (let i = 0; i < 500; i++) expect(isCode(makeCode(Math.random))).toBe(true);
  });
  it("rejects bad codes", () => {
    for (const c of ["FROG42", "frog-42", "FR-42", "FROGGY-42", "FROG-4", "FROG-421", ""]) expect(isCode(c)).toBe(false);
  });
  it("has enough friendly words", () => {
    expect(WORDS.length).toBeGreaterThanOrEqual(120);
    expect(new Set(WORDS).size).toBe(WORDS.length);
    for (const w of WORDS) expect(w).toMatch(/^[A-Z]{3,5}$/);
  });
  it("uses the random source", () => {
    expect(makeCode(() => 0)).toBe(`${WORDS[0]}-00`);
    expect(makeCode(() => 0.999999)).toBe(`${WORDS[WORDS.length - 1]}-99`);
  });
});
