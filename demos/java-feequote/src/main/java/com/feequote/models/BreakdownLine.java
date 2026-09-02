package com.feequote.models;

/**
 * One labeled component of a quoted fee.
 *
 * @param label the name of the component, as shown to the customer
 * @param amountCents the component amount in integer cents
 */
public record BreakdownLine(String label, long amountCents) {
}
