namespace FeeQuote.Models;

/// <summary>
/// A customer payment transfer as received from a channel. Amounts are whole
/// cents; the currency and country codes are validated by the transfer service
/// against <see cref="Config.Settings"/>.
/// </summary>
/// <param name="Id">Caller-supplied identifier, echoed on the quote and receipt.</param>
/// <param name="AmountCents">Principal amount in minor units.</param>
/// <param name="Currency">ISO 4217 code, for example AUD.</param>
/// <param name="OriginCountry">ISO 3166-1 alpha-2 code of the sending account.</param>
/// <param name="DestinationCountry">ISO 3166-1 alpha-2 code of the receiving account.</param>
/// <param name="Channel">Where the transfer was initiated (online, branch, api).</param>
public sealed record Transfer(
    string Id,
    long AmountCents,
    string Currency,
    string OriginCountry,
    string DestinationCountry,
    string Channel);
