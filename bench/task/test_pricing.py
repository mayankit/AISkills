"""Existing suite — must stay green. This is the real gate for the task."""
from pricing import subtotal, _round_money


def test_round_money_is_half_up_not_bankers():
    assert _round_money(2.675) == 2.68
    assert _round_money(0.125) == 0.13


def test_subtotal_rounds_the_total():
    # 0.105 + 0.105 = 0.21 exactly; a float sum + naive round gives 0.2099999...
    assert subtotal([(0.105, 1), (0.105, 1)]) == 0.21
