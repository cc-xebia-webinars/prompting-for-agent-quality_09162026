package com.feequote.services;

import com.feequote.clients.PaymentClient;
import com.feequote.clients.SubmissionReceipt;
import com.feequote.config.Settings;
import com.feequote.core.Pricing;
import com.feequote.models.BreakdownLine;
import com.feequote.models.Quote;
import com.feequote.models.Transfer;
import java.util.List;
import org.springframework.stereotype.Service;

/** Quoting and submission of customer transfers. */
@Service
public class TransferService {

    /**
     * A quoted transfer that has been handed to the gateway.
     *
     * @param quote the price the customer was given
     * @param receipt what the gateway returned
     */
    public record Submission(Quote quote, SubmissionReceipt receipt) {
    }

    private final PaymentClient client;

    public TransferService(PaymentClient client) {
        this.client = client;
    }

    /** Rejects transfers the service cannot price or route. */
    public static void validateTransfer(Transfer transfer) {
        if (transfer.amountCents() <= 0) {
            throw new TransferValidationException("amountCents must be positive");
        }
        if (!Settings.CURRENCIES.contains(transfer.currency())) {
            throw new TransferValidationException("unsupported currency: " + transfer.currency());
        }
        if (!Settings.COUNTRIES.contains(transfer.originCountry())) {
            throw new TransferValidationException("unsupported origin country: " + transfer.originCountry());
        }
        if (!Settings.COUNTRIES.contains(transfer.destinationCountry())) {
            throw new TransferValidationException(
                    "unsupported destination country: " + transfer.destinationCountry());
        }
        if (!Settings.CHANNELS.contains(transfer.channel())) {
            throw new TransferValidationException("unsupported channel: " + transfer.channel());
        }
    }

    /** Prices {@code transfer} and returns the quote with its fee breakdown. */
    public Quote quote(Transfer transfer) {
        validateTransfer(transfer);
        long domesticFee = Pricing.computeFee(transfer.amountCents());
        List<BreakdownLine> breakdown = List.of(new BreakdownLine("domesticFee", domesticFee));
        long feeCents = breakdown.stream().mapToLong(BreakdownLine::amountCents).sum();
        return new Quote(transfer.id(), feeCents, transfer.amountCents() + feeCents, breakdown);
    }

    /** Quotes {@code transfer} and hands it to the gateway. */
    public Submission submit(Transfer transfer) {
        Quote quote = quote(transfer);
        return new Submission(quote, client.submit(transfer));
    }
}
