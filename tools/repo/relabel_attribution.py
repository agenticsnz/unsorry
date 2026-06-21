"""Relabel deterministic-template proofs from `claude` to `python/sympy` on main.

ohdearquant's `mac-158f` pipeline produced proofs with a deterministic Python/sympy
template engine, but recorded them as `provider≜claude; model≜template-*`, which the
leaderboard renders as `claude / template-…` — overstating LLM involvement. The
honest record is `provider≜python; model≜sympy` (the contributor's own correction,
originally #3218).

A one-shot PR cannot fix this against a live corpus (it conflicts and is always
incomplete as the pipeline keeps producing). This is the idempotent **sweep** that
replaces it: run periodically on `main`, it rewrites every matching record and
no-ops once they are all corrected — self-healing as new ones arrive.

Precise + conservative. A record is relabelled only when it carries **all three**
signals: `agent≜mac-158f`, `provider≜claude`, and `model≜template-*`. This leaves
untouched (a) genuine LLM proofs by the same agent (e.g. `model≜sonnet`),
(b) `seedkit` template fixtures (`provider≜seedkit`), and (c) any other contributor.
Solver/credit (`solver≜…`) is never changed — ranking is unaffected.

Usage:
  python3 -m tools.repo.relabel_attribution            # dry-run under . : count what changes
  python3 -m tools.repo.relabel_attribution --apply .  # rewrite the files under the given root
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

AGENT = "mac-158f"
_MODEL_TEMPLATE_RE = re.compile(r"model≜template-[^;}\s]*")
# Records carrying provenance that the leaderboard reads.
SCAN_GLOBS = (
    "library/index/*.aisp",
    "packages/unsorry-archive-*/library/index/*.aisp",
    "proof-runs/*.aisp",
)


def relabel_record(text: str) -> tuple[str, bool]:
    """Return (text, changed). Rewrites provider/model to python/sympy iff the
    record is one of the deterministic-template proofs (all three signals present).
    Idempotent: a record already python/sympy, or not a template proof, is unchanged."""
    if f"agent≜{AGENT}" not in text:
        return text, False
    if "provider≜claude" not in text:
        return text, False
    if not _MODEL_TEMPLATE_RE.search(text):
        return text, False
    new = text.replace("provider≜claude", "provider≜python")
    new = _MODEL_TEMPLATE_RE.sub("model≜sympy", new)
    return new, new != text


def _iter_files(root: Path):
    for pattern in SCAN_GLOBS:
        yield from root.glob(pattern)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.relabel_attribution",
        description="Relabel mac-158f template proofs from claude to python/sympy.")
    # Positional root, matching the repo's other path-scanning tools
    # (`tools.gate_b validate .`, `tools.leaderboard --check .`): the
    # attribution-relabel workflow invokes us as `… --apply .`, so the root
    # must be accepted positionally, not only via a flag.
    ap.add_argument("root", nargs="?", default=".",
                    help="repository root to scan (default: .)")
    ap.add_argument("--apply", action="store_true", help="rewrite files (default: dry-run)")
    args = ap.parse_args(argv)

    root = Path(args.root)
    changed = 0
    for path in _iter_files(root):
        text = path.read_text(encoding="utf-8")
        new, did = relabel_record(text)
        if did:
            changed += 1
            if args.apply:
                path.write_text(new, encoding="utf-8")
    verb = "relabelled" if args.apply else "would relabel"
    print(f"attribution relabel: {verb} {changed} record(s) "
          f"(agent≜{AGENT} + provider≜claude + model≜template-* → python/sympy)"
          f"{'' if args.apply else ' [DRY-RUN]'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
