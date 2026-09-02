"""Retry with exponential backoff."""

from collections.abc import Iterator

import pytest

from feequote.clients.payment_client import GatewayError
from feequote.clients.retry import with_retry


def test_returns_the_first_successful_result() -> None:
    outcomes: Iterator[GatewayError | str] = iter([GatewayError("1"), GatewayError("2"), "ok"])
    delays: list[float] = []

    def call() -> str:
        outcome = next(outcomes)
        if isinstance(outcome, GatewayError):
            raise outcome
        return outcome

    assert with_retry(call, attempts=3, backoff_ms=100, sleep=delays.append) == "ok"
    assert delays == [0.1, 0.2]


def test_delay_doubles_after_each_failure() -> None:
    delays: list[float] = []

    def call() -> str:
        raise GatewayError("down")

    with pytest.raises(GatewayError):
        with_retry(call, attempts=4, backoff_ms=200, sleep=delays.append)
    assert delays == [0.2, 0.4, 0.8]


def test_raises_the_last_error_when_attempts_run_out() -> None:
    calls: list[int] = []

    def call() -> str:
        calls.append(1)
        raise GatewayError(f"attempt {len(calls)}")

    with pytest.raises(GatewayError, match="attempt 3"):
        with_retry(call, attempts=3, backoff_ms=0, sleep=lambda _: None)
    assert len(calls) == 3


def test_does_not_retry_unexpected_errors() -> None:
    calls: list[int] = []

    def call() -> str:
        calls.append(1)
        raise KeyError("not a gateway problem")

    with pytest.raises(KeyError):
        with_retry(call, attempts=3, backoff_ms=0, sleep=lambda _: None)
    assert len(calls) == 1


def test_retry_on_widens_the_retried_exceptions() -> None:
    outcomes: Iterator[TimeoutError | str] = iter([TimeoutError("slow"), "ok"])

    def call() -> str:
        outcome = next(outcomes)
        if isinstance(outcome, TimeoutError):
            raise outcome
        return outcome

    result = with_retry(call, backoff_ms=0, sleep=lambda _: None, retry_on=(TimeoutError,))
    assert result == "ok"


def test_rejects_bad_settings() -> None:
    with pytest.raises(ValueError, match="attempts"):
        with_retry(lambda: "x", attempts=0)
    with pytest.raises(ValueError, match="backoff_ms"):
        with_retry(lambda: "x", backoff_ms=-1)
