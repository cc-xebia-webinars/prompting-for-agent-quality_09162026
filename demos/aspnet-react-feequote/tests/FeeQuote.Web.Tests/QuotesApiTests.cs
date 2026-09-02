using System.Net;
using System.Net.Http.Json;
using FeeQuote.Web.Controllers.Api;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Testing;

namespace FeeQuote.Web.Tests;

public sealed class QuotesApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _http;

    public QuotesApiTests(WebApplicationFactory<Program> factory)
    {
        _http = factory.CreateClient();
    }

    private static CancellationToken Token => TestContext.Current.CancellationToken;

    [Fact]
    public async Task PostQuotes_PlainDomesticTransfer_ReturnsQuoteWithBreakdown()
    {
        var request = new QuoteRequest(100000, "AUD", "AU", "AU", "online");

        using var response = await _http.PostAsJsonAsync("/api/quotes", request, Token);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var quote = await response.Content.ReadFromJsonAsync<QuoteResponse>(Token);
        Assert.NotNull(quote);
        Assert.Equal(100000, quote.AmountCents);
        Assert.Equal("AUD", quote.Currency);
        Assert.Equal(900, quote.FeeCents);
        Assert.Equal(100900, quote.TotalCents);
        var line = Assert.Single(quote.Breakdown);
        Assert.Equal("Domestic fee", line.Label);
        Assert.Equal(900, line.AmountCents);
    }

    [Fact]
    public async Task PostQuotes_MissingChannel_UsesDefaultChannel()
    {
        var request = new QuoteRequest(123500, "aud", "au", "au", null);

        using var response = await _http.PostAsJsonAsync("/api/quotes", request, Token);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var quote = await response.Content.ReadFromJsonAsync<QuoteResponse>(Token);
        Assert.NotNull(quote);
        Assert.Equal(1112, quote.FeeCents);
    }

    [Fact]
    public async Task PostQuotes_UnsupportedCurrency_ReturnsValidationProblem()
    {
        var request = new QuoteRequest(100000, "XXX", "AU", "AU", "online");

        using var response = await _http.PostAsJsonAsync("/api/quotes", request, Token);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ValidationProblemDetails>(Token);
        Assert.NotNull(problem);
        Assert.Contains("XXX", problem.Errors["transfer"][0], StringComparison.Ordinal);
    }

    [Fact]
    public async Task PostQuotes_ZeroAmount_ReturnsBadRequest()
    {
        var request = new QuoteRequest(0, "AUD", "AU", "AU", "online");

        using var response = await _http.PostAsJsonAsync("/api/quotes", request, Token);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Health_ReturnsOk()
    {
        using var response = await _http.GetAsync("/health", Token);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
