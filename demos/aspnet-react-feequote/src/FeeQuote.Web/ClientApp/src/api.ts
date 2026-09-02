// Typed client for the FeeQuote API. Field names mirror the JSON contract
// served by QuotesController; keep them in sync when the API changes.

export interface QuoteRequest {
  amountCents: number;
  currency: string;
  originCountry: string;
  destinationCountry: string;
  channel: string;
}

export interface BreakdownLine {
  label: string;
  amountCents: number;
}

export interface QuoteResponse {
  transferId: string;
  amountCents: number;
  currency: string;
  feeCents: number;
  totalCents: number;
  breakdown: BreakdownLine[];
}

interface ProblemDetails {
  title?: string;
  errors?: Record<string, string[]>;
}

export class ApiError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

export const REFERENCE = {
  currencies: ["AUD", "NZD", "USD", "GBP", "EUR"],
  countries: ["AU", "NZ", "US", "GB", "DE"],
  channels: ["online", "branch", "api"],
} as const;

/** Posts a quote request and returns the parsed quote, or throws ApiError. */
export async function requestQuote(
  request: QuoteRequest,
  fetchImpl: typeof fetch = fetch,
): Promise<QuoteResponse> {
  const response = await fetchImpl("/api/quotes", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(request),
  });

  if (!response.ok) {
    throw new ApiError(response.status, await describeProblem(response));
  }

  return (await response.json()) as QuoteResponse;
}

async function describeProblem(response: Response): Promise<string> {
  try {
    const problem = (await response.json()) as ProblemDetails;
    const messages = Object.values(problem.errors ?? {}).flat();
    if (messages.length > 0) {
      return messages.join(" ");
    }
    return problem.title ?? `Request failed with status ${response.status}`;
  } catch {
    return `Request failed with status ${response.status}`;
  }
}
