package com.feequote.clients;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

class RetryTest {

    /** Records the delays it was asked to wait instead of actually waiting. */
    private static final class RecordingSleeper implements Retry.Sleeper {

        private final List<Long> delays = new ArrayList<>();

        @Override
        public void sleep(long millis) {
            delays.add(millis);
        }
    }

    @Test
    void returnsTheFirstSuccessWithoutSleeping() {
        RecordingSleeper sleeper = new RecordingSleeper();

        String result = Retry.withRetry(() -> "ok", 3, 200, sleeper);

        assertThat(result).isEqualTo("ok");
        assertThat(sleeper.delays).isEmpty();
    }

    @Test
    void retriesAGatewayFailureAndSucceedsOnALaterAttempt() {
        RecordingSleeper sleeper = new RecordingSleeper();
        AtomicInteger calls = new AtomicInteger();

        String result = Retry.withRetry(() -> {
            if (calls.incrementAndGet() < 3) {
                throw new GatewayException("gateway timeout");
            }
            return "ok";
        }, 3, 200, sleeper);

        assertThat(result).isEqualTo("ok");
        assertThat(calls).hasValue(3);
    }

    @Test
    void backoffDoublesAfterEachFailure() {
        RecordingSleeper sleeper = new RecordingSleeper();

        assertThatThrownBy(() -> Retry.withRetry(() -> {
            throw new GatewayException("gateway timeout");
        }, 3, 200, sleeper)).isInstanceOf(GatewayException.class);

        assertThat(sleeper.delays).containsExactly(200L, 400L);
    }

    @Test
    void rethrowsTheLastFailureWhenAttemptsRunOut() {
        RecordingSleeper sleeper = new RecordingSleeper();
        AtomicInteger calls = new AtomicInteger();

        assertThatThrownBy(() -> Retry.withRetry(() -> {
            throw new GatewayException("gateway failure " + calls.incrementAndGet());
        }, 2, 10, sleeper))
                .isInstanceOf(GatewayException.class)
                .hasMessage("gateway failure 2");
        assertThat(calls).hasValue(2);
    }

    @Test
    void doesNotRetryAnythingOtherThanAGatewayFailure() {
        RecordingSleeper sleeper = new RecordingSleeper();
        AtomicInteger calls = new AtomicInteger();

        assertThatThrownBy(() -> Retry.withRetry(() -> {
            calls.incrementAndGet();
            throw new IllegalStateException("a bug in the caller");
        }, 3, 200, sleeper)).isInstanceOf(IllegalStateException.class);

        assertThat(calls).hasValue(1);
        assertThat(sleeper.delays).isEmpty();
    }

    @Test
    void doesNotRetryErrorsTheFilterRejects() {
        RecordingSleeper sleeper = new RecordingSleeper();
        AtomicInteger calls = new AtomicInteger();

        assertThatThrownBy(() -> Retry.withRetry(() -> {
            calls.incrementAndGet();
            throw new GatewayException("gateway failure");
        }, 3, 200, sleeper, failure -> false)).isInstanceOf(GatewayException.class);

        assertThat(calls).hasValue(1);
        assertThat(sleeper.delays).isEmpty();
    }

    @Test
    void rejectsAnImpossibleAttemptCountOrBackoff() {
        RecordingSleeper sleeper = new RecordingSleeper();

        assertThatThrownBy(() -> Retry.withRetry(() -> "ok", 0, 200, sleeper))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("attempts");
        assertThatThrownBy(() -> Retry.withRetry(() -> "ok", 3, -1, sleeper))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("backoffMs");
    }
}
