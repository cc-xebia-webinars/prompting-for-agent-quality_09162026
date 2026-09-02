package com.feequote.clients;

/**
 * What the gateway returns once it has taken a transfer.
 *
 * @param transferId the transfer that was submitted
 * @param reference the gateway's own reference for the submission
 * @param status the gateway's verdict, for example "accepted"
 */
public record SubmissionReceipt(String transferId, String reference, String status) {
}
