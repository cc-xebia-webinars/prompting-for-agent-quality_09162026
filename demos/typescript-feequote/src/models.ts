// Domain types. All money is an integer number of minor units (cents).
import type { Channel, Country, Currency } from './config.js';

export interface Transfer {
  readonly id: string;
  readonly amountCents: number;
  readonly currency: Currency;
  readonly originCountry: Country;
  readonly destinationCountry: Country;
  readonly channel: Channel;
}

/** One labelled line of a quote, for example "Domestic fee". */
export interface BreakdownLine {
  readonly label: string;
  readonly amountCents: number;
}

export interface Quote {
  readonly transferId: string;
  /** Sum of every breakdown line. */
  readonly feeCents: number;
  /** Transfer amount plus feeCents. */
  readonly totalCents: number;
  readonly breakdown: readonly BreakdownLine[];
}
