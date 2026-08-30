"""Existing suite — must stay green. The real gate for the task."""
from orders import sort_orders


def test_sort_orders_newest_first():
    got = sort_orders([
        {"customer_id": 1, "name": "Sam", "ts": 10, "amount": 5},
        {"customer_id": 1, "name": "Sam", "ts": 30, "amount": 9},
    ])
    assert [o["ts"] for o in got] == [30, 10]
