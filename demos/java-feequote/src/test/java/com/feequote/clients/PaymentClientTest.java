package com.feequote.clients;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.feequote.models.Transfer;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class PaymentClientTest {

    private static Transfer transfer(long amountCents) {
        return new Transfer("tr-1", amountCents, "AUD", "AU", "AU", "online");
    }

    @Test
    void submitReturnsAnAcceptedReceiptFromTheTransport() {
        PaymentClient client = new PaymentClient((seen, key) -> "REF-1");

        SubmissionReceipt receipt = client.submit(transfer(100000));

        assertThat(receipt.transferId()).isEqualTo("tr-1");
        assertThat(receipt.reference()).isEqualTo("REF-1");
        assertThat(receipt.status()).isEqualTo("accepted");
    }

    @Test
    void submitPassesTheTransferToTheTransport() {
        List<Transfer> sent = new ArrayList<>();
        PaymentClient client = new PaymentClient((seen, key) -> {
            sent.add(seen);
            return "REF-1";
        });

        client.submit(transfer(100000));

        assertThat(sent).containsExactly(transfer(100000));
    }

    @Test
    void theStubTransportHandsOutSequentialReferences() {
        PaymentClient client = new PaymentClient();

        assertThat(client.submit(transfer(100000)).reference()).isEqualTo("STUB-000001");
        assertThat(client.submit(transfer(100000)).reference()).isEqualTo("STUB-000002");
    }

    @Test
    void submitSendsAnIdempotencyKey() {
        List<String> keys = new ArrayList<>();
        PaymentClient client = new PaymentClient((seen, key) -> {
            keys.add(key);
            return "REF-1";
        });

        client.submit(transfer(100000));

        assertThat(keys).singleElement().asString().isNotBlank();
    }

    @Test
    void submitRejectsANonPositiveAmountBeforeReachingTheTransport() {
        List<Transfer> sent = new ArrayList<>();
        PaymentClient client = new PaymentClient((seen, key) -> {
            sent.add(seen);
            return "REF-1";
        });

        assertThatThrownBy(() -> client.submit(transfer(0)))
                .isInstanceOf(GatewayException.class)
                .hasMessageContaining("non-positive amount");
        assertThat(sent).isEmpty();
    }
}
