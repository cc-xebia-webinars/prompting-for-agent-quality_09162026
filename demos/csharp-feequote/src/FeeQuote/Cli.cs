using System.Globalization;
using System.Text.Json;
using FeeQuote.Clients;
using FeeQuote.Config;
using FeeQuote.Models;
using FeeQuote.Services;

namespace FeeQuote;

/// <summary>
/// Command-line front end. Parsing and formatting are separate from
/// <see cref="Program.Main"/> so they can be tested without spawning a process.
/// </summary>
public static class Cli
{
    public const string Usage =
        "usage: feequote quote --amount <cents> --from <country> --to <country>" +
        " [--currency <code>] [--channel <name>] [--id <transfer-id>]";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = true,
    };

    /// <summary>Runs the CLI and returns the process exit code (0 ok, 2 usage error).</summary>
    public static int Run(string[] args, TextWriter stdout, TextWriter stderr)
    {
        ArgumentNullException.ThrowIfNull(args);
        ArgumentNullException.ThrowIfNull(stdout);
        ArgumentNullException.ThrowIfNull(stderr);

        if (args.Length == 0 || !string.Equals(args[0], "quote", StringComparison.Ordinal))
        {
            stderr.WriteLine(Usage);
            return 2;
        }

        try
        {
            Transfer transfer = ParseQuoteArgs(args[1..]);
            Quote quote = new TransferService(new PaymentClient()).Quote(transfer);
            stdout.WriteLine(FormatQuote(quote));
            return 0;
        }
        catch (ArgumentException ex)
        {
            stderr.WriteLine($"error: {ex.Message}");
            stderr.WriteLine(Usage);
            return 2;
        }
    }

    /// <summary>Builds a <see cref="Transfer"/> from the options that follow the quote command.</summary>
    public static Transfer ParseQuoteArgs(IReadOnlyList<string> args)
    {
        ArgumentNullException.ThrowIfNull(args);

        long? amount = null;
        string? from = null;
        string? to = null;
        string currency = Settings.DefaultCurrency;
        string channel = Settings.DefaultChannel;
        string id = Guid.NewGuid().ToString("N")[..12];

        for (int i = 0; i < args.Count; i += 2)
        {
            string option = args[i];
            if (i + 1 >= args.Count)
            {
                throw new ArgumentException($"Option {option} needs a value.");
            }

            string value = args[i + 1];
            switch (option)
            {
                case "--amount":
                    amount = ParseAmount(value);
                    break;
                case "--from":
                    from = value.ToUpperInvariant();
                    break;
                case "--to":
                    to = value.ToUpperInvariant();
                    break;
                case "--currency":
                    currency = value.ToUpperInvariant();
                    break;
                case "--channel":
                    channel = value.ToLowerInvariant();
                    break;
                case "--id":
                    id = value;
                    break;
                default:
                    throw new ArgumentException($"Unknown option {option}.");
            }
        }

        if (amount is null || from is null || to is null)
        {
            throw new ArgumentException("--amount, --from and --to are required.");
        }

        return new Transfer(id, amount.Value, currency, from, to, channel);
    }

    /// <summary>Serialises a quote as indented camelCase JSON.</summary>
    public static string FormatQuote(Quote quote)
    {
        return JsonSerializer.Serialize(quote, JsonOptions);
    }

    private static long ParseAmount(string value)
    {
        if (!long.TryParse(value, NumberStyles.None, CultureInfo.InvariantCulture, out long cents) || cents <= 0)
        {
            throw new ArgumentException($"--amount must be a positive whole number of cents, got '{value}'.");
        }

        return cents;
    }
}
