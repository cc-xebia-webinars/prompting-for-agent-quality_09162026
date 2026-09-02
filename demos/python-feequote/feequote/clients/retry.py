"""Retry with exponential backoff for calls to external systems.

Wrap any call that can fail transiently (gateway timeouts, connection
resets) with ``with_retry`` instead of writing a loop at the call site, so
every path retries the same way and tests can inject a fake ``sleep``.
"""

from __future__ import annotations

import time
from collections.abc import Callable

from feequote.clients.errors import GatewayError

DEFAULT_ATTEMPTS = 3
DEFAULT_BACKOFF_MS = 200


def with_retry[T](
    fn: Callable[[], T],
    attempts: int = DEFAULT_ATTEMPTS,
    backoff_ms: int = DEFAULT_BACKOFF_MS,
    sleep: Callable[[float], None] = time.sleep,
    retry_on: tuple[type[Exception], ...] = (GatewayError,),
) -> T:
    """Call ``fn`` until it succeeds or ``attempts`` is exhausted.

    The delay starts at ``backoff_ms`` and doubles after each failure, so the
    defaults wait 200 ms and then 400 ms. Only exceptions listed in
    ``retry_on`` are retried; anything else is a bug in the caller and
    propagates immediately. The last error is re-raised when attempts run out.
    """
    if attempts < 1:
        raise ValueError("attempts must be at least 1")
    if backoff_ms < 0:
        raise ValueError("backoff_ms must not be negative")
    delay_ms = backoff_ms
    for attempt in range(1, attempts + 1):
        try:
            return fn()
        except retry_on:
            if attempt == attempts:
                raise
            sleep(delay_ms / 1000)
            delay_ms *= 2
    raise AssertionError("unreachable: the loop returns or raises")
