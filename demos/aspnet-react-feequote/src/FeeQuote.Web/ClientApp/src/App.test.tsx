import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import App from "./App";
import type { QuoteResponse } from "./api";

const plainQuote: QuoteResponse = {
  transferId: "t-1",
  amountCents: 100000,
  currency: "AUD",
  feeCents: 900,
  totalCents: 100900,
  breakdown: [{ label: "Domestic fee", amountCents: 900 }],
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function mockFetch(response: Response) {
  const fetchMock = vi.fn<typeof fetch>().mockResolvedValue(response);
  vi.stubGlobal("fetch", fetchMock);
  return fetchMock;
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("App", () => {
  it("renders the quote form with reference data", () => {
    render(<App />);

    expect(screen.getByRole("form", { name: "Quote request" })).toBeInTheDocument();
    expect(screen.getByLabelText("Amount")).toHaveValue("1,000.00");
    expect(screen.getByLabelText("Currency")).toHaveValue("AUD");
    expect(screen.getByRole("button", { name: "Get quote" })).toBeEnabled();
  });

  it("posts the form as cents and renders the breakdown and total", async () => {
    const fetchMock = mockFetch(jsonResponse(plainQuote));
    render(<App />);

    fireEvent.change(screen.getByLabelText("Amount"), { target: { value: "1,000.00" } });
    fireEvent.click(screen.getByRole("button", { name: "Get quote" }));

    await screen.findByRole("table", { name: "Quote breakdown" });
    expect(screen.getByText("Domestic fee")).toBeInTheDocument();
    expect(screen.getByText("AUD 9.00")).toBeInTheDocument();
    expect(screen.getByText("AUD 1,009.00")).toBeInTheDocument();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(url).toBe("/api/quotes");
    expect(JSON.parse(init!.body as string)).toEqual({
      amountCents: 100000,
      currency: "AUD",
      originCountry: "AU",
      destinationCountry: "AU",
      channel: "online",
    });
  });

  it("shows the API validation message when the request is rejected", async () => {
    mockFetch(jsonResponse({ errors: { transfer: ["Unsupported currency 'XXX'."] } }, 400));
    render(<App />);

    fireEvent.click(screen.getByRole("button", { name: "Get quote" }));

    await waitFor(() => {
      expect(screen.getByRole("alert")).toHaveTextContent("Unsupported currency 'XXX'.");
    });
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });

  it("does not call the API when the amount is not a valid money value", () => {
    const fetchMock = mockFetch(jsonResponse(plainQuote));
    render(<App />);

    fireEvent.change(screen.getByLabelText("Amount"), { target: { value: "12.345" } });
    fireEvent.click(screen.getByRole("button", { name: "Get quote" }));

    expect(screen.getByRole("alert")).toHaveTextContent("Enter an amount");
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
