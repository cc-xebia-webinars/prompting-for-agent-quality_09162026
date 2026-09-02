package com.feequote.clients;

/** The gateway did not respond in time. */
public class GatewayTimeoutException extends GatewayException {

    private static final long serialVersionUID = 1L;

    public GatewayTimeoutException(String message) {
        super(message);
    }
}
