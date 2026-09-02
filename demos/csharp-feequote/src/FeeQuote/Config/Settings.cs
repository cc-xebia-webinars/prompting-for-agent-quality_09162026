namespace FeeQuote.Config;

/// <summary>
/// Static reference data for the quoting service. These lists are small enough
/// to live in code; they change through a normal release rather than at runtime.
/// </summary>
public static class Settings
{
    /// <summary>Currencies a transfer may be denominated in.</summary>
    public static IReadOnlyList<string> Currencies { get; } = ["AUD", "NZD", "USD", "GBP", "EUR"];

    /// <summary>Countries we can send from and to.</summary>
    public static IReadOnlyList<string> Countries { get; } = ["AU", "NZ", "US", "GB", "DE", "SG"];

    /// <summary>Channels that may originate a transfer.</summary>
    public static IReadOnlyList<string> Channels { get; } = ["online", "branch", "api"];

    /// <summary>Currency assumed when a channel does not supply one.</summary>
    public const string DefaultCurrency = "AUD";

    /// <summary>Channel assumed when a caller does not supply one.</summary>
    public const string DefaultChannel = "online";
}
