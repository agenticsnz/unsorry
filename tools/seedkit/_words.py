#!/usr/bin/env python3
"""Number-word table shared across the seedkit generators and writers.

Goal ids use the grammar ``[a-z0-9][a-z0-9-]*`` and, by convention, spell small
integer parameters as English words (``gzmod-156-pow-seven-sub-pow-three``,
``telescoping-cube-sum-coeff-twelve``). Every generator/writer needs the same
``int -> word`` map; keeping the single copy here is the DRY source (ADR/CLAUDE
"DRY") and means a goal id minted by a generator and one minted by its writer
can never disagree on spelling.

``WORDS`` covers ``1..80`` — wide enough for the coefficient/value sweeps the
closed-form families run (lower ranges having been consumed by earlier batches).
Import the slice you need; do not redefine the table locally.
"""
from __future__ import annotations

_ONES = ["", "one", "two", "three", "four", "five", "six", "seven", "eight",
         "nine"]
_TEENS = {
    10: "ten", 11: "eleven", 12: "twelve", 13: "thirteen", 14: "fourteen",
    15: "fifteen", 16: "sixteen", 17: "seventeen", 18: "eighteen",
    19: "nineteen",
}
_TENS = {20: "twenty", 30: "thirty", 40: "forty", 50: "fifty", 60: "sixty",
         70: "seventy", 80: "eighty"}


def _word(n: int) -> str:
    if n < 10:
        return _ONES[n]
    if n < 20:
        return _TEENS[n]
    if n % 10 == 0:
        return _TENS[n]
    return _TENS[(n // 10) * 10] + _ONES[n % 10]


WORDS: dict[int, str] = {n: _word(n) for n in range(1, 81)}
