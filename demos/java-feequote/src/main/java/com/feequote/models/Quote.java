package com.feequote.models;

import java.util.List;

/**
 * The fee quoted for a transfer.
 *
 * <p>{@code feeCents} is the sum of every breakdown line. {@code totalCents} is the
 * transfer amount plus {@code feeCents}, which is what the customer is debited.
 *
 * @param transferId the transfer this quote prices
 * @param feeCents the total fee in integer cents
 * @param totalCents the amount plus the fee, in integer cents
 * @param breakdown the labeled components that make up the fee
 */
public record Quote(String transferId, long feeCents, long totalCents, List<BreakdownLine> breakdown) {

    public Quote {
        breakdown = List.copyOf(breakdown);
    }
}
