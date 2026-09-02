package com.feequote.clients;

import com.feequote.models.Transfer;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * Payment gateway client.
 *
 * <p>The gateway integration is stubbed: submissions are accepted locally and given
 * a sequential reference. The transport can be swapped for tests or for a real
 * adapter without touching the callers.
 */
@Component
public class PaymentClient {

    /** Sends a transfer to the gateway and returns the gateway reference. */
    @FunctionalInterface
    public interface Transport {
        String send(Transfer transfer, String idempotencyKey);
    }

    private final Transport transport;

    /** Builds a client on the stubbed local transport. */
    @Autowired
    public PaymentClient() {
        this(new StubTransport());
    }

    /** Builds a client on {@code transport}. */
    public PaymentClient(Transport transport) {
        this.transport = transport;
    }

    /** Sends {@code transfer} to the gateway and returns its receipt. */
    public SubmissionReceipt submit(Transfer transfer) {
        if (transfer.amountCents() <= 0) {
            throw new GatewayException("transfer " + transfer.id() + " has a non-positive amount");
        }
        String reference = send(transfer);
        return new SubmissionReceipt(transfer.id(), reference, "accepted");
    }

    private String send(Transfer transfer) {
        return transport.send(transfer, newIdempotencyKey());
    }

    private static String newIdempotencyKey() {
        return UUID.randomUUID().toString();
    }

    /** Accepts everything and hands back a sequential local reference. */
    static final class StubTransport implements Transport {

        private final AtomicLong sequence = new AtomicLong();
        private final Map<String, String> referencesByKey = new ConcurrentHashMap<>();

        @Override
        public String send(Transfer transfer, String idempotencyKey) {
            return referencesByKey.computeIfAbsent(
                    idempotencyKey, key -> String.format("STUB-%06d", sequence.incrementAndGet()));
        }
    }
}
