import { useState } from "react";
import type { FormEvent } from "react";
import { ApiError, REFERENCE, requestQuote } from "./api";
import type { QuoteResponse } from "./api";
import { formatCents, parseAmountToCents } from "./money";

interface FormState {
  amount: string;
  currency: string;
  originCountry: string;
  destinationCountry: string;
  channel: string;
}

const initialForm: FormState = {
  amount: "1,000.00",
  currency: "AUD",
  originCountry: "AU",
  destinationCountry: "AU",
  channel: "online",
};

export default function App() {
  const [form, setForm] = useState<FormState>(initialForm);
  const [quote, setQuote] = useState<QuoteResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const update = (field: keyof FormState) => (value: string) =>
    setForm((current) => ({ ...current, [field]: value }));

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);

    const amountCents = parseAmountToCents(form.amount);
    if (amountCents === null) {
      setQuote(null);
      setError("Enter an amount greater than zero with at most two decimal places.");
      return;
    }

    setBusy(true);
    try {
      setQuote(
        await requestQuote({
          amountCents,
          currency: form.currency,
          originCountry: form.originCountry,
          destinationCountry: form.destinationCountry,
          channel: form.channel,
        }),
      );
    } catch (caught) {
      setQuote(null);
      setError(caught instanceof ApiError ? caught.message : "The quote service is unavailable.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="quote">
      <h1>Transfer fee quote</h1>
      <form onSubmit={handleSubmit} aria-label="Quote request">
        <label>
          Amount
          <input
            name="amount"
            inputMode="decimal"
            value={form.amount}
            onChange={(e) => update("amount")(e.target.value)}
          />
        </label>
        <Select label="Currency" name="currency" value={form.currency} options={REFERENCE.currencies} onChange={update("currency")} />
        <Select label="From country" name="originCountry" value={form.originCountry} options={REFERENCE.countries} onChange={update("originCountry")} />
        <Select label="To country" name="destinationCountry" value={form.destinationCountry} options={REFERENCE.countries} onChange={update("destinationCountry")} />
        <Select label="Channel" name="channel" value={form.channel} options={REFERENCE.channels} onChange={update("channel")} />
        <button type="submit" disabled={busy}>
          {busy ? "Quoting" : "Get quote"}
        </button>
      </form>

      {error && (
        <p role="alert" className="error">
          {error}
        </p>
      )}

      {quote && <QuoteTable quote={quote} />}
    </main>
  );
}

interface SelectProps {
  label: string;
  name: string;
  value: string;
  options: readonly string[];
  onChange: (value: string) => void;
}

function Select({ label, name, value, options, onChange }: SelectProps) {
  return (
    <label>
      {label}
      <select name={name} value={value} onChange={(e) => onChange(e.target.value)}>
        {options.map((option) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
      </select>
    </label>
  );
}

function QuoteTable({ quote }: { quote: QuoteResponse }) {
  return (
    <table className="breakdown" aria-label="Quote breakdown">
      <tbody>
        <tr>
          <th scope="row">Amount</th>
          <td>{formatCents(quote.amountCents, quote.currency)}</td>
        </tr>
        {quote.breakdown.map((line) => (
          <tr key={line.label} className="fee-line">
            <th scope="row">{line.label}</th>
            <td>{formatCents(line.amountCents, quote.currency)}</td>
          </tr>
        ))}
        <tr className="total">
          <th scope="row">Total to debit</th>
          <td>{formatCents(quote.totalCents, quote.currency)}</td>
        </tr>
      </tbody>
    </table>
  );
}
