// Static reference data. Anything that changes per environment belongs in the
// deployment configuration, not here.

export const CURRENCIES = ['AUD', 'NZD', 'USD', 'GBP', 'EUR'] as const;
export type Currency = (typeof CURRENCIES)[number];

export const COUNTRIES = ['AU', 'NZ', 'US', 'GB', 'DE', 'SG'] as const;
export type Country = (typeof COUNTRIES)[number];

export const CHANNELS = ['online', 'branch', 'api'] as const;
export type Channel = (typeof CHANNELS)[number];

export const DEFAULT_CURRENCY: Currency = 'AUD';
export const DEFAULT_CHANNEL: Channel = 'online';

export function isCurrency(value: string): value is Currency {
  return (CURRENCIES as readonly string[]).includes(value);
}

export function isCountry(value: string): value is Country {
  return (COUNTRIES as readonly string[]).includes(value);
}

export function isChannel(value: string): value is Channel {
  return (CHANNELS as readonly string[]).includes(value);
}
