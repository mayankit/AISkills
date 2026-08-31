"""Existing suite — must stay green. The real gate."""
import store, cache


def setup_function(_):
    cache._reset()


def test_read_through_and_cached():
    cache.write("alpha", 1)
    assert cache.read("alpha") == 1
    store.drop("alpha")            # cache still has it
    assert cache.read("alpha") == 1
