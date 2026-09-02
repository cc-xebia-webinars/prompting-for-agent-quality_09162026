package com.feequote.services;

/** The transfer cannot be quoted as supplied. */
public class TransferValidationException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    public TransferValidationException(String message) {
        super(message);
    }
}
