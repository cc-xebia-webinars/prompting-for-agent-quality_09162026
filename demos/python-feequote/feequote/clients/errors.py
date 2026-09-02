"""Errors raised by adapters for external systems."""


class GatewayError(RuntimeError):
    """The gateway did not accept the submission."""


class GatewayTimeoutError(GatewayError):
    """The gateway did not respond in time."""


class GatewayDeclinedError(GatewayError):
    """The gateway declined the transfer."""
