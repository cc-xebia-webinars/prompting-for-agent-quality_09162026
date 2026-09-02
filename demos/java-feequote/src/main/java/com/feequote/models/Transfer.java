package com.feequote.models;

/**
 * A customer payment transfer awaiting a quote or submission.
 *
 * @param id the transfer reference
 * @param amountCents the amount in integer cents
 * @param currency the ISO currency code
 * @param originCountry the ISO country code the money leaves
 * @param destinationCountry the ISO country code the money arrives in
 * @param channel the channel the transfer was raised through
 */
public record Transfer(
        String id,
        long amountCents,
        String currency,
        String originCountry,
        String destinationCountry,
        String channel) {
}
