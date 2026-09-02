"""Static configuration: supported currencies, countries and channels.

These are deliberately plain constants. Anything that needs to vary per
environment belongs in deployment configuration, not here.
"""

from __future__ import annotations

CURRENCIES: frozenset[str] = frozenset({"AUD", "NZD", "USD", "GBP", "EUR", "SGD"})
DEFAULT_CURRENCY = "AUD"

COUNTRIES: frozenset[str] = frozenset({"AU", "NZ", "US", "GB", "IE", "SG", "FJ", "PG"})
DEFAULT_COUNTRY = "AU"

CHANNELS: tuple[str, ...] = ("online", "branch", "api")
DEFAULT_CHANNEL = "online"
