import { describe, expect, it } from "vitest";
import { formatCents, parseAmountToCents } from "./money";

describe("formatCents", () => {
  it("formats whole and fractional cents with the currency code", () => {
    expect(formatCents(123500, "AUD")).toBe("AUD 1,235.00");
    expect(formatCents(1112, "AUD")).toBe("AUD 11.12");
    expect(formatCents(5, "NZD")).toBe("NZD 0.05");
  });

  it("groups thousands", () => {
    expect(formatCents(100000000, "USD")).toBe("USD 1,000,000.00");
  });

  it("keeps the sign in front of the currency code", () => {
    expect(formatCents(-250, "GBP")).toBe("-GBP 2.50");
  });

  it("rejects non-integer cents", () => {
    expect(() => formatCents(10.5, "AUD")).toThrow(RangeError);
  });
});

describe("parseAmountToCents", () => {
  it("accepts plain and grouped decimal input", () => {
    expect(parseAmountToCents("1235")).toBe(123500);
    expect(parseAmountToCents("1,235.00")).toBe(123500);
    expect(parseAmountToCents("0.5")).toBe(50);
  });

  it("rejects zero, negative, and over-precise input", () => {
    expect(parseAmountToCents("0")).toBeNull();
    expect(parseAmountToCents("-5")).toBeNull();
    expect(parseAmountToCents("1.234")).toBeNull();
    expect(parseAmountToCents("abc")).toBeNull();
  });
});
