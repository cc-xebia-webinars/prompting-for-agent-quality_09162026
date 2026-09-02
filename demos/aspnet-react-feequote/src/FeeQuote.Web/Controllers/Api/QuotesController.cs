using System.ComponentModel.DataAnnotations;
using FeeQuote.Web.Domain.Config;
using FeeQuote.Web.Domain.Models;
using FeeQuote.Web.Domain.Services;
using Microsoft.AspNetCore.Mvc;

namespace FeeQuote.Web.Controllers.Api;

/// <summary>Request body for POST /api/quotes.</summary>
public sealed record QuoteRequest(
    [Range(1, long.MaxValue)] long AmountCents,
    [Required] string Currency,
    [Required] string OriginCountry,
    [Required] string DestinationCountry,
    string? Channel);

/// <summary>Response body for POST /api/quotes. Field names are the public contract.</summary>
public sealed record QuoteResponse(
    string TransferId,
    long AmountCents,
    string Currency,
    long FeeCents,
    long TotalCents,
    IReadOnlyList<BreakdownLine> Breakdown);

[ApiController]
[Route("api/quotes")]
[Produces("application/json")]
public sealed class QuotesController : ControllerBase
{
    private readonly TransferService _transfers;

    public QuotesController(TransferService transfers)
    {
        _transfers = transfers;
    }

    [HttpPost]
    [ProducesResponseType<QuoteResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public ActionResult<QuoteResponse> Create([FromBody] QuoteRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var transfer = new Transfer(
            Id: Guid.NewGuid().ToString("N"),
            AmountCents: request.AmountCents,
            Currency: request.Currency.ToUpperInvariant(),
            OriginCountry: request.OriginCountry.ToUpperInvariant(),
            DestinationCountry: request.DestinationCountry.ToUpperInvariant(),
            Channel: string.IsNullOrWhiteSpace(request.Channel) ? Settings.DefaultChannel : request.Channel);

        try
        {
            var quote = _transfers.Quote(transfer);
            return Ok(new QuoteResponse(
                quote.TransferId,
                transfer.AmountCents,
                transfer.Currency,
                quote.FeeCents,
                quote.TotalCents,
                quote.Breakdown));
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError("transfer", ex.Message);
            return ValidationProblem(ModelState);
        }
    }
}
