package com.feequote.clients;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.feequote.models.Transfer;
import com.feequote.services.TransferService;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * Presenter-only check for segment 4.3. Never commit this file.
 *
 * <p>Copy it into a worktree's {@code src/test/java/com/feequote/clients} folder after the
 * agent has finished, then run only this class. It drives the submit path through the
 * transfer service with a fake gateway, so it holds wherever the agent put the retry.
 */
class PaymentClientTierCheckTest {

    private static final Transfer TRANSFER = new Transfer("tr-4300", 100000, "AUD", "AU", "AU", "online");

    /** Deduplicates on the idempotency key, like the real gateway. */
    private static final class FakeGateway implements PaymentClient.Transport {

        private final boolean loseFirstResponse;
        private final boolean failFirstCall;
        private final boolean decline;
        private final List<String> calls = new ArrayList<>();
        private final Map<String, String> payments = new LinkedHashMap<>();

        private FakeGateway(boolean loseFirstResponse, boolean failFirstCall, boolean decline) {
            this.loseFirstResponse = loseFirstResponse;
            this.failFirstCall = failFirstCall;
            this.decline = decline;
        }

        @Override
        public synchronized String send(Transfer transfer, String idempotencyKey) {
            calls.add(idempotencyKey);
            if (decline) {
                throw new GatewayDeclinedException("transfer " + transfer.id() + " declined");
            }
            if (failFirstCall && calls.size() == 1) {
                throw new GatewayTimeoutException("gateway timed out before taking the payment");
            }
            payments.computeIfAbsent(idempotencyKey, key -> "GW-" + (payments.size() + 1));
            if (loseFirstResponse && calls.size() == 1) {
                throw new GatewayTimeoutException("gateway took the payment but the response was lost");
            }
            return payments.get(idempotencyKey);
        }
    }

    private static String submitThrough(FakeGateway gateway) {
        TransferService service = new TransferService(new PaymentClient(gateway));
        return service.submit(TRANSFER).receipt().reference();
    }

    @Test
    void recoversWhenTheGatewayTimesOutOnce() {
        FakeGateway gateway = new FakeGateway(false, true, false);

        assertThat(submitThrough(gateway))
                .withFailMessage("the submit path does not retry a timeout")
                .isEqualTo("GW-1");
    }

    @Test
    void chargesTheCustomerOnceWhenAResponseIsLost() {
        FakeGateway gateway = new FakeGateway(true, false, false);

        String reference = submitThrough(gateway);

        int charges = gateway.payments.size();
        assertThat(charges)
                .withFailMessage("customer charged %d times for %s (keys: %s)",
                        charges, TRANSFER.id(), String.join(", ", gateway.payments.keySet()))
                .isEqualTo(1);
        assertThat(reference).isEqualTo("GW-1");
    }

    @Test
    void doesNotResubmitADeclinedTransfer() {
        FakeGateway gateway = new FakeGateway(false, false, true);

        assertThatThrownBy(() -> submitThrough(gateway)).isInstanceOf(RuntimeException.class);
        assertThat(gateway.calls.size())
                .withFailMessage("declined transfer sent %d times", gateway.calls.size())
                .isEqualTo(1);
    }
}
