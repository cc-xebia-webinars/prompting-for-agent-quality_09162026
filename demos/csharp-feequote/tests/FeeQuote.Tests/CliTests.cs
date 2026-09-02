using System.Text.Json;
using FeeQuote.Models;

namespace FeeQuote.Tests;

public class CliTests
{
    [Fact]
    public void ParseQuoteArgs_ReadsRequiredOptionsAndAppliesDefaults()
    {
        Transfer transfer = Cli.ParseQuoteArgs(["--amount", "123500", "--from", "au", "--to", "AU"]);

        Assert.Equal(123500, transfer.AmountCents);
        Assert.Equal("AU", transfer.OriginCountry);
        Assert.Equal("AU", transfer.DestinationCountry);
        Assert.Equal("AUD", transfer.Currency);
        Assert.Equal("online", transfer.Channel);
        Assert.False(string.IsNullOrWhiteSpace(transfer.Id));
    }

    [Fact]
    public void ParseQuoteArgs_HonoursOptionalOverrides()
    {
        Transfer transfer = Cli.ParseQuoteArgs(
            ["--amount", "5000", "--from", "NZ", "--to", "AU", "--currency", "nzd", "--channel", "API", "--id", "x1"]);

        Assert.Equal("NZD", transfer.Currency);
        Assert.Equal("api", transfer.Channel);
        Assert.Equal("x1", transfer.Id);
    }

    [Theory]
    [InlineData("--from", "AU", "--to", "AU")] // amount missing
    [InlineData("--amount", "-5", "--from", "AU", "--to", "AU")] // negative amount
    [InlineData("--amount", "12.50", "--from", "AU", "--to", "AU")] // not whole cents
    [InlineData("--amount", "100", "--from", "AU", "--to")] // dangling option
    [InlineData("--amount", "100", "--from", "AU", "--to", "AU", "--colour", "blue")] // unknown option
    public void ParseQuoteArgs_RejectsMalformedInput(params string[] args)
    {
        Assert.Throws<ArgumentException>(() => Cli.ParseQuoteArgs(args));
    }

    [Fact]
    public void FormatQuote_WritesCamelCaseJsonWithBreakdown()
    {
        var quote = new Quote("q1", 1112, 124612, [new BreakdownLine("Domestic fee", 1112)]);

        using JsonDocument document = JsonDocument.Parse(Cli.FormatQuote(quote));

        JsonElement root = document.RootElement;
        Assert.Equal("q1", root.GetProperty("transferId").GetString());
        Assert.Equal(1112, root.GetProperty("feeCents").GetInt64());
        Assert.Equal(124612, root.GetProperty("totalCents").GetInt64());
        JsonElement line = Assert.Single(root.GetProperty("breakdown").EnumerateArray());
        Assert.Equal("Domestic fee", line.GetProperty("label").GetString());
        Assert.Equal(1112, line.GetProperty("amountCents").GetInt64());
    }

    [Fact]
    public void Run_QuoteCommand_PrintsQuoteAndReturnsZero()
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        int exitCode = Cli.Run(["quote", "--amount", "123500", "--from", "AU", "--to", "AU", "--id", "t1"], stdout, stderr);

        Assert.Equal(0, exitCode);
        Assert.Equal(string.Empty, stderr.ToString());
        using JsonDocument document = JsonDocument.Parse(stdout.ToString());
        Assert.Equal(1112, document.RootElement.GetProperty("feeCents").GetInt64());
    }

    [Fact]
    public void Run_UnknownCommand_PrintsUsageAndReturnsTwo()
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        int exitCode = Cli.Run(["refund"], stdout, stderr);

        Assert.Equal(2, exitCode);
        Assert.Equal(string.Empty, stdout.ToString());
        Assert.Contains("usage:", stderr.ToString(), StringComparison.Ordinal);
    }

    [Fact]
    public void Run_InvalidCountry_ReportsValidationErrorAndReturnsTwo()
    {
        var stdout = new StringWriter();
        var stderr = new StringWriter();

        int exitCode = Cli.Run(["quote", "--amount", "100", "--from", "AU", "--to", "ZZ"], stdout, stderr);

        Assert.Equal(2, exitCode);
        Assert.Contains("destination country", stderr.ToString(), StringComparison.Ordinal);
    }
}
