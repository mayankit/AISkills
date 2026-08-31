"""Order-history helpers."""


def _key(o):
    return (o["customer_id"], o["ts"])


def sort_orders(orders):
    """Newest first, stable within a customer."""
    return sorted(orders, key=_key, reverse=True)
