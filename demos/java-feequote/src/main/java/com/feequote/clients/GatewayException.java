package com.feequote.clients;

/** The gateway did not accept the submission. */
public class GatewayException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    public GatewayException(String message) {
        super(message);
    }
}
