#!/usr/bin/env python3
"""Widened variant of :mod:`gen_gzmod`: exponent gap up to 18 and exponents up
to 30, which makes many more mid-size moduli productive (a modulus is productive
only when its Carmichael ``λ(M)`` divides some admissible gap). The enumeration
and truth-checking logic lives entirely in :mod:`gen_gzmod`; this module only
changes the default caps. Run from the repository root.
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_gzmod  # noqa: E402


def main(argv=None):
    parser = gen_gzmod.build_parser()
    parser.set_defaults(bmax=12, dmax=18, amax=30)
    args = parser.parse_args(argv)
    mods = [int(x) for x in args.mods.split(",") if x.strip()]
    gen_gzmod.run(mods, args.bmax, args.dmax, args.amax, args.limit)


if __name__ == "__main__":
    main()
