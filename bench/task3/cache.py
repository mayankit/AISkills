"""A read-through cache over `store`. Cache keys are normalised to lowercase;
the store keeps them verbatim. Keep the two conventions straight."""

import store

_CACHE = {}


def _ck(key):
    return key.lower()


def read(key):
    ck = _ck(key)
    if ck in _CACHE:
        return _CACHE[ck]
    value = store.get(key)          # store is case-sensitive — use the raw key
    _CACHE[ck] = value
    return value


def write(key, value):
    store.put(key, value)
    _CACHE[_ck(key)] = value


def _reset():
    _CACHE.clear()
    store._reset()
