/**
 * Formats an integer number of minor units as "CUR 1,234.56". Formatting is
 * done by hand rather than through Intl so the output does not depend on the
 * browser locale data; the API returns cents and the UI only displays them.
 */
export function formatCents(cents: number, currency: string): string {
  if (!Number.isInteger(cents)) {
    throw new RangeError(`Amount must be an integer number of cents, got ${cents}`);
  }

  const sign = cents < 0 ? "-" : "";
  const absolute = Math.abs(cents);
  const whole = Math.floor(absolute / 100);
  const fraction = absolute % 100;

  const grouped = whole.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return `${sign}${currency} ${grouped}.${fraction.toString().padStart(2, "0")}`;
}

/** Parses a user-entered amount such as "1,234.50" into cents, or null if unusable. */
export function parseAmountToCents(input: string): number | null {
  const cleaned = input.replace(/[\s,]/g, "");
  if (!/^\d+(\.\d{1,2})?$/.test(cleaned)) {
    return null;
  }

  const [wholePart = "0", fractionPart = ""] = cleaned.split(".");
  const cents = Number(wholePart) * 100 + Number(fractionPart.padEnd(2, "0"));
  return cents > 0 ? cents : null;
}
