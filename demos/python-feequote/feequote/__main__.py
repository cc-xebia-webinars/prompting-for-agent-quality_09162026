"""Command line entry point.

    python -m feequote quote --amount 123500 --from AU --to AU

Prints the quote as JSON on stdout. Validation problems go to stderr with a
non-zero exit code so the command is safe to use from scripts.
"""

from __future__ import annotations

import argparse
import json
import sys
import uuid
from collections.abc import Sequence

from feequote import config
from feequote.models import Transfer
from feequote.services.transfer_service import TransferService, TransferValidationError

EXIT_OK = 0
EXIT_INVALID = 2


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="feequote", description="Quote fees for transfers.")
    commands = parser.add_subparsers(dest="command", required=True)

    quote = commands.add_parser("quote", help="print a fee quote as JSON")
    quote.add_argument("--amount", type=int, required=True, help="transfer amount in cents")
    quote.add_argument("--from", dest="origin", default=config.DEFAULT_COUNTRY, help="origin")
    quote.add_argument("--to", dest="destination", default=config.DEFAULT_COUNTRY, help="dest")
    quote.add_argument("--currency", default=config.DEFAULT_CURRENCY)
    quote.add_argument("--channel", default=config.DEFAULT_CHANNEL, choices=config.CHANNELS)
    quote.add_argument("--id", dest="transfer_id", help="transfer id (generated when omitted)")
    return parser


def run_quote(args: argparse.Namespace) -> int:
    transfer = Transfer(
        id=args.transfer_id or f"tr-{uuid.uuid4().hex[:8]}",
        amount_cents=args.amount,
        currency=args.currency,
        origin_country=args.origin,
        destination_country=args.destination,
        channel=args.channel,
    )
    try:
        quote = TransferService().quote(transfer)
    except TransferValidationError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return EXIT_INVALID
    print(json.dumps(quote.to_dict(), indent=2))
    return EXIT_OK


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command == "quote":
        return run_quote(args)
    parser.error(f"unknown command: {args.command}")


if __name__ == "__main__":
    sys.exit(main())
