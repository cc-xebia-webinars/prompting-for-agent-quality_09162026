package com.feequote.web;

import com.feequote.config.Settings;
import com.feequote.models.BreakdownLine;
import com.feequote.models.Quote;
import com.feequote.models.Transfer;
import com.feequote.services.TransferService;
import com.feequote.services.TransferValidationException;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** The quoting endpoint. Field names on the request and the response are the public contract. */
@RestController
@RequestMapping("/api/quotes")
public class QuotesController {

    /** Request body for POST /api/quotes. */
    public record QuoteRequest(
            @Positive long amountCents,
            @NotBlank String currency,
            @NotBlank String originCountry,
            @NotBlank String destinationCountry,
            String channel) {
    }

    /** Response body for POST /api/quotes. */
    public record QuoteResponse(
            String transferId,
            long amountCents,
            String currency,
            long feeCents,
            long totalCents,
            List<BreakdownLine> breakdown) {
    }

    private final TransferService transfers;

    public QuotesController(TransferService transfers) {
        this.transfers = transfers;
    }

    /** Prices a transfer and returns the quote with its fee breakdown. */
    @PostMapping
    public QuoteResponse create(@Valid @RequestBody QuoteRequest request) {
        Transfer transfer = new Transfer(
                UUID.randomUUID().toString().replace("-", ""),
                request.amountCents(),
                upper(request.currency()),
                upper(request.originCountry()),
                upper(request.destinationCountry()),
                blankToDefault(request.channel()));

        Quote quote = transfers.quote(transfer);
        return new QuoteResponse(
                quote.transferId(),
                transfer.amountCents(),
                transfer.currency(),
                quote.feeCents(),
                quote.totalCents(),
                quote.breakdown());
    }

    /** A transfer the service cannot price is a bad request, not a server error. */
    @ExceptionHandler(TransferValidationException.class)
    public ProblemDetail onValidationFailure(TransferValidationException failure) {
        ProblemDetail problem = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        problem.setTitle("The transfer cannot be quoted");
        problem.setDetail(failure.getMessage());
        return problem;
    }

    private static String upper(String value) {
        return value.toUpperCase(Locale.ROOT);
    }

    private static String blankToDefault(String channel) {
        if (channel == null || channel.isBlank()) {
            return Settings.DEFAULT_CHANNEL;
        }
        return channel;
    }
}
