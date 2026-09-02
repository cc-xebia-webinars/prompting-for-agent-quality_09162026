"""Command line entry point."""

import json
import subprocess
import sys
from pathlib import Path

import pytest

from feequote.__main__ import main

REPO_ROOT = Path(__file__).resolve().parent.parent


def test_quote_prints_json(capsys: pytest.CaptureFixture[str]) -> None:
    exit_code = main(["quote", "--amount", "123500", "--from", "AU", "--to", "AU", "--id", "tr-1"])

    assert exit_code == 0
    payload = json.loads(capsys.readouterr().out)
    assert payload == {
        "transfer_id": "tr-1",
        "fee_cents": 1112,
        "total_cents": 124612,
        "breakdown": [{"label": "domestic_fee", "amount_cents": 1112}],
    }


def test_quote_generates_an_id_when_none_is_given(capsys: pytest.CaptureFixture[str]) -> None:
    assert main(["quote", "--amount", "100000"]) == 0
    payload = json.loads(capsys.readouterr().out)
    assert payload["transfer_id"].startswith("tr-")


def test_quote_reports_validation_errors_on_stderr(capsys: pytest.CaptureFixture[str]) -> None:
    exit_code = main(["quote", "--amount", "100000", "--currency", "XXX"])

    captured = capsys.readouterr()
    assert exit_code == 2
    assert captured.out == ""
    assert "unsupported currency: XXX" in captured.err


def test_module_runs_as_a_script() -> None:
    command = [sys.executable, "-m", "feequote", "quote", "--amount", "100000", "--id", "tr-2"]
    result = subprocess.run(command, cwd=REPO_ROOT, capture_output=True, text=True, check=True)

    payload = json.loads(result.stdout)
    assert payload["transfer_id"] == "tr-2"
    assert payload["fee_cents"] == 900
    assert payload["total_cents"] == 100900
