"""Pricing helpers for the storefront."""

from decimal import Decimal, ROUND_HALF_UP

# Regional sales-tax rates. Add regions here, not in call sites.
TAX_RATES = {"us": 0.08, "eu": 0.20, "ca": 0.12}


def _round_money(amount):
    """Round to whole cents, half-up.

    Money rounding must not go through binary float / builtin round() (which is
    banker's rounding and drifts on values like 2.675). Everything monetary in
    this module goes through here.
    """
    return float(Decimal(str(amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def subtotal(items):
    """items: iterable of (unit_price, quantity) pairs. Returns rounded subtotal."""
    return _round_money(sum(price * qty for price, qty in items))
