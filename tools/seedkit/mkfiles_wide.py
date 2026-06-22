#!/usr/bin/env python3
"""Widened variant of :mod:`mkfiles`: supports exponents up to 30 (the range the
widened generator emits). Reuses :func:`mkfiles.write_goal`; only the
number-word table is extended. Run from the repository root::

    python3 tools/seedkit/mkfiles_wide.py <M> <a> <b>
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mkfiles  # noqa: E402

WORDS = dict(mkfiles.WORDS)
WORDS.update({
    21: "twentyone", 22: "twentytwo", 23: "twentythree", 24: "twentyfour",
    25: "twentyfive", 26: "twentysix", 27: "twentyseven", 28: "twentyeight",
    29: "twentynine", 30: "thirty",
})


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) < 3:
        sys.exit("usage: mkfiles_wide.py <M> <a> <b>")
    M, a, b = (int(x) for x in argv[:3])
    print(mkfiles.write_goal(M, a, b, words=WORDS))


if __name__ == "__main__":
    main()
