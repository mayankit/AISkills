"""A tiny case-SENSITIVE key/value store. Keys are used verbatim."""

_DATA = {}


class KeyMissing(Exception):
    pass


def put(key, value):
    _DATA[key] = value


def get(key):
    if key not in _DATA:
        raise KeyMissing(key)
    return _DATA[key]


def drop(key):
    _DATA.pop(key, None)


def _reset():
    _DATA.clear()
