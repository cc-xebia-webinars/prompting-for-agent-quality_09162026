package com.feequote.clients;

/** The gateway declined the transfer. */
public class GatewayDeclinedException extends GatewayException {

    private static final long serialVersionUID = 1L;

    public GatewayDeclinedException(String message) {
        super(message);
    }
}
