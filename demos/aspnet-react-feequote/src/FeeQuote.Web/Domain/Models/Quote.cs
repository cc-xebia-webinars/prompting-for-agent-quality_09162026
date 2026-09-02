namespace FeeQuote.Web.Domain.Models;

/// <summary>One labelled line of a quote breakdown, in cents.</summary>
public sealed record BreakdownLine(string Label, long AmountCents);

/// <summary>
/// The priced result for a transfer. <see cref="FeeCents"/> is the sum of the
/// breakdown lines and <see cref="TotalCents"/> is the principal plus fees,
/// which is the amount debited from the customer.
/// </summary>
public sealed record Quote(
    string TransferId,
    long FeeCents,
    long TotalCents,
    IReadOnlyList<BreakdownLine> Breakdown);
