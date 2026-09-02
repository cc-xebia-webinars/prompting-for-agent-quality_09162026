package com.feequote.services;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.feequote.clients.PaymentClient;
import com.feequote.models.BreakdownLine;
import com.feequote.models.Quote;
import com.feequote.models.Transfer;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class TransferServiceTest {

    private static Transfer transfer(long amountCents) {
        return new Transfer("tr-1", amountCents, "AUD", "AU", "AU", "online");
    }

    private static TransferService service() {
        return new TransferService(new PaymentClient());
    }

    @Test
    void regressionTicket4821() {
        // The legacy helper returns 1111 here because it truncates. See ticket 4821.
        Quote quote = service().quote(transfer(123500));
        assertThat(quote.feeCents()).isEqualTo(1112);
    }

    @Test
    void quoteBreakdownHasASingleDomesticLine() {
        Quote quote = service().quote(transfer(100000));
        assertThat(quote.breakdown()).containsExactly(new BreakdownLine("domesticFee", 900));
    }

    @Test
    void quoteTotalIsAmountPlusFee() {
        Quote quote = service().quote(transfer(100000));
        assertThat(quote.transferId()).isEqualTo("tr-1");
        assertThat(quote.feeCents()).isEqualTo(900);
        assertThat(quote.totalCents()).isEqualTo(100900);
    }

    @Test
    void quoteAppliesMinimumAndCap() {
        TransferService service = service();
        assertThat(service.quote(transfer(5000)).feeCents()).isEqualTo(100);
        assertThat(service.quote(transfer(500000)).feeCents()).isEqualTo(2500);
    }

    @ParameterizedTest(name = "{0}")
    @CsvSource({
        "XXX, AU, AU, online, unsupported currency",
        "AUD, ZZ, AU, online, unsupported origin country",
        "AUD, AU, ZZ, online, unsupported destination country",
        "AUD, AU, AU, fax,    unsupported channel",
    })
    void quoteRejectsUnsupportedTransfers(
            String currency, String origin, String destination, String channel, String message) {
        Transfer unsupported = new Transfer("tr-1", 100000, currency, origin, destination, channel);
        assertThatThrownBy(() -> service().quote(unsupported))
                .isInstanceOf(TransferValidationException.class)
                .hasMessageContaining(message);
    }

    @Test
    void quoteRejectsNonPositiveAmounts() {
        assertThatThrownBy(() -> service().quote(transfer(0)))
                .isInstanceOf(TransferValidationException.class)
                .hasMessageContaining("amountCents");
    }

    @Test
    void submitQuotesThenSendsThroughTheClient() {
        List<Transfer> sent = new ArrayList<>();
        TransferService service = new TransferService(new PaymentClient((seen, key) -> {
            sent.add(seen);
            return "REF-1";
        }));

        TransferService.Submission submission = service.submit(transfer(100000));

        assertThat(submission.quote().feeCents()).isEqualTo(900);
        assertThat(submission.receipt().reference()).isEqualTo("REF-1");
        assertThat(submission.receipt().status()).isEqualTo("accepted");
        assertThat(sent).extracting(Transfer::id).containsExactly("tr-1");
    }

    @Test
    void submitDoesNotReachTheClientWhenValidationFails() {
        List<Transfer> sent = new ArrayList<>();
        TransferService service = new TransferService(new PaymentClient((seen, key) -> {
            sent.add(seen);
            return "REF-1";
        }));
        Transfer unsupported = new Transfer("tr-1", 100000, "XXX", "AU", "AU", "online");

        assertThatThrownBy(() -> service.submit(unsupported))
                .isInstanceOf(TransferValidationException.class);
        assertThat(sent).isEmpty();
    }
}
