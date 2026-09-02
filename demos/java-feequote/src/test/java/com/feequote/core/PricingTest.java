package com.feequote.core;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class PricingTest {

    @ParameterizedTest(name = "{0}")
    @CsvSource({
        "ticket 4821 rounding, 123500, 1112",
        "cap applies,          500000, 2500",
        "minimum applies,        5000,  100",
        "plain,                100000,  900",
    })
    void computeFeeWorkedExamples(String name, long amountCents, long expectedFeeCents) {
        assertThat(Pricing.computeFee(amountCents)).isEqualTo(expectedFeeCents);
    }

    @Test
    void domesticPolicyValues() {
        assertThat(Pricing.DOMESTIC_RATE_BPS).isEqualTo(90);
        assertThat(Pricing.DOMESTIC_POLICY.minimumCents()).isEqualTo(100);
        assertThat(Pricing.DOMESTIC_POLICY.capCents()).isEqualTo(2500);
    }

    @Test
    void roundHalfEvenRoundsAHalfTowardsTheEvenQuotient() {
        assertThat(Pricing.roundHalfEvenDiv(11115, 10)).isEqualTo(1112);
        assertThat(Pricing.roundHalfEvenDiv(11125, 10)).isEqualTo(1112);
        assertThat(Pricing.roundHalfEvenDiv(11135, 10)).isEqualTo(1114);
    }

    @Test
    void roundHalfEvenLeavesAnythingShortOfAHalfAlone() {
        assertThat(Pricing.roundHalfEvenDiv(111105, 100)).isEqualTo(1111);
        assertThat(Pricing.roundHalfEvenDiv(111195, 100)).isEqualTo(1112);
    }

    @Test
    void roundHalfEvenRejectsNegativeAndZeroInputs() {
        assertThatThrownBy(() -> Pricing.roundHalfEvenDiv(100, 0))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("denominator");
        assertThatThrownBy(() -> Pricing.roundHalfEvenDiv(-1, 10))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("numerator");
    }

    @Test
    void priceWithPolicyAppliesTheRateBeforeTheBounds() {
        FeePolicy generous = new FeePolicy(0, 1_000_000);
        assertThat(Pricing.priceWithPolicy(500000, 90, generous)).isEqualTo(4500);
        assertThat(Pricing.priceWithPolicy(5000, 90, generous)).isEqualTo(45);
    }

    @Test
    void priceWithPolicyCarriesAnyRate() {
        assertThat(Pricing.priceWithPolicy(247100, 50, Pricing.DOMESTIC_POLICY)).isEqualTo(1236);
        assertThat(Pricing.priceWithPolicy(1000000, 50, Pricing.DOMESTIC_POLICY)).isEqualTo(2500);
    }

    @Test
    void priceWithPolicyRejectsNegativeAmountsAndRates() {
        assertThatThrownBy(() -> Pricing.priceWithPolicy(-1, 90, Pricing.DOMESTIC_POLICY))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("amountCents");
        assertThatThrownBy(() -> Pricing.priceWithPolicy(100000, -1, Pricing.DOMESTIC_POLICY))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("rateBps");
    }

    @Test
    void feePolicyClampsIntoItsRange() {
        FeePolicy policy = new FeePolicy(100, 2500);
        assertThat(policy.apply(45)).isEqualTo(100);
        assertThat(policy.apply(900)).isEqualTo(900);
        assertThat(policy.apply(4500)).isEqualTo(2500);
    }

    @Test
    void feePolicyRejectsAnImpossibleRange() {
        assertThatThrownBy(() -> new FeePolicy(-1, 2500))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("minimumCents");
        assertThatThrownBy(() -> new FeePolicy(2500, 100))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("capCents");
    }
}
