namespace FeeQuote.Web.Domain.Models;

/// <summary>
/// A customer payment transfer as received from a channel. Amounts are integer
/// minor units (cents); binary floating point is never used for money.
/// </summary>
/// <param name="Id">Caller-supplied identifier, unique per transfer.</param>
/// <param name="AmountCents">Principal amount in cents, must be positive.</param>
/// <param name="Currency">ISO 4217 code, see <see cref="Config.Settings.Currencies"/>.</param>
/// <param name="OriginCountry">ISO 3166-1 alpha-2 code of the sending account.</param>
/// <param name="DestinationCountry">ISO 3166-1 alpha-2 code of the receiving account.</param>
/// <param name="Channel">Originating channel, see <see cref="Config.Settings.Channels"/>.</param>
public sealed record Transfer(
    string Id,
    long AmountCents,
    string Currency,
    string OriginCountry,
    string DestinationCountry,
    string Channel);
