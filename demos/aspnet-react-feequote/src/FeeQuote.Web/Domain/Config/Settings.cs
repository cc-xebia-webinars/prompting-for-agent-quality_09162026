namespace FeeQuote.Web.Domain.Config;

/// <summary>
/// Reference data the service accepts. Kept in code rather than configuration
/// because a change here needs a pricing review, not a deployment toggle.
/// </summary>
public static class Settings
{
    /// <summary>Currencies a transfer may be denominated in.</summary>
    public static IReadOnlyList<string> Currencies { get; } = ["AUD", "NZD", "USD", "GBP", "EUR"];

    /// <summary>Countries we can send from and to.</summary>
    public static IReadOnlyList<string> Countries { get; } = ["AU", "NZ", "US", "GB", "DE"];

    /// <summary>Channels that can originate a transfer.</summary>
    public static IReadOnlyList<string> Channels { get; } = ["online", "branch", "api"];

    /// <summary>Channel assumed when the caller does not say.</summary>
    public const string DefaultChannel = "online";
}
