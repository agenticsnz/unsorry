"""Deterministic minimal-import candidate generator for proof modules (ADR-074).

The prover almost always emits the broad `import Mathlib` (it is the always-builds
default, and the prove prompt rightly hammers on soundness over import hygiene).
The cost lands in CI: every Gate A job — library build, kernel replay, and the
axiom audit — must load mathlib's entire olean closure (~10 GB). Measured, the
axiom-audit step alone drops from ~281 s to ~141 s (~2x) when one ZMod proof is
narrowed to `Mathlib.Data.ZMod.Basic` + `Mathlib.Tactic` (#2397).

This module maps observable features of a proof's *source* to the much smaller
import set that covers them. The caller (`swarm/agent.sh`) writes the narrow set,
re-verifies, and falls back to `import Mathlib` on any failure (SPEC-074-A) — so
narrowing can never reject a sound proof; it only shrinks the closure when it
provably still builds.

Deterministic and conservative by design:
  * narrows ONLY when the file uses the broad `import Mathlib` default (a prover
    that already chose tight imports is left untouched), and
  * proposes a narrow set ONLY when a known math feature is present (an unmatched
    proof keeps `import Mathlib` rather than emitting a set sure to fall back).
Coverage grows by adding `FEATURE_MODULES` rows as new proof families appear.
"""
from __future__ import annotations

import re
import sys

BROAD_IMPORT = "import Mathlib"

# Tactic blocks need their defining modules imported to re-elaborate, yet those
# modules leave no constant in the finished term — so they cannot be inferred from
# the proof's constant closure. Import the umbrella, which is far smaller than full
# Mathlib while covering push_cast / norm_cast / exact_mod_cast / ring / decide etc.
TACTIC_UMBRELLA = "import Mathlib.Tactic"

# Feature token (regex) -> the module that provides it. Math modules come first in
# the emitted block; the tactic umbrella (if needed) is appended last.
FEATURE_MODULES: list[tuple[str, str]] = [
    (r"\bZMod\b", "import Mathlib.Data.ZMod.Basic"),
]

# Tactics whose presence means the proof re-elaborates only with the tactic modules
# available. Kept broad: a missing entry just means we skip the umbrella and the
# narrow set falls back if a tactic is in fact unavailable.
TACTIC_TOKENS = (
    "push_cast", "norm_cast", "exact_mod_cast", "mod_cast", "norm_num",
    "ring", "ring_nf", "field_simp", "linarith", "nlinarith", "positivity",
    "gcongr", "omega", "decide", "simp",
)


def candidate_imports(source: str) -> list[str] | None:
    """Return a narrowed import block for `source`, or None to leave it unchanged.

    Returns a list of full `import …` lines (math modules first, tactic umbrella
    last) when narrowing applies, else None.
    """
    import_lines = [ln.strip() for ln in source.splitlines()
                    if ln.strip().startswith("import ")]
    if import_lines != [BROAD_IMPORT]:
        # Already narrow, or no/multiple imports — respect the prover's choice.
        return None

    modules: list[str] = []
    for token, module in FEATURE_MODULES:
        if re.search(token, source) and module not in modules:
            modules.append(module)
    if not modules:
        # No known math mapping: a tactic-only block would miss the proof's lemmas
        # and fall back anyway, so propose nothing.
        return None

    if any(tok in source for tok in TACTIC_TOKENS):
        modules.append(TACTIC_UMBRELLA)
    return modules


def rewrite_imports(source: str, modules: list[str]) -> str:
    """Replace the single broad `import Mathlib` line with `modules`, body intact."""
    out: list[str] = []
    replaced = False
    for line in source.splitlines(keepends=True):
        if not replaced and line.strip() == BROAD_IMPORT:
            newline = "\n" if line.endswith("\n") else ""
            out.append("\n".join(modules) + newline)
            replaced = True
        else:
            out.append(line)
    return "".join(out)


def main(argv: list[str] | None = None) -> int:
    """CLI: print the narrowed module to stdout (rc 0), or rc 1 if no narrowing."""
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 1:
        print("usage: python3 -m tools.proof.min_imports <module.lean>",
              file=sys.stderr)
        return 2
    with open(args[0], encoding="utf-8") as fh:
        source = fh.read()
    modules = candidate_imports(source)
    if not modules:
        return 1
    sys.stdout.write(rewrite_imports(source, modules))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
