"""Relabel deterministic-template proofs mis-recorded as `claude` to their honest
provider/model on main.

Two contributors recorded deterministic, non-LLM proofs as `provider≜claude;
model≜template-*`, which the leaderboard renders as a `claude / …` model attribution —
overstating LLM involvement:

* ohdearquant's `mac-158f` pipeline used a deterministic Python/sympy template engine;
  the honest record is `provider≜python; model≜sympy` (the contributor's own
  correction, originally #3218; convention set by ADR-079).
* chat-bit-01's `claude-web` `template-zmod-decide` proofs are a pure Lean kernel
  `decide` over a finite `ZMod n` (no LLM, no Python/sympy); the honest record is
  `provider≜lean; model≜decide`.

A one-shot PR cannot fix this against a live corpus (it conflicts and is always
incomplete as the pipelines keep producing). This is the idempotent **sweep** that
replaces it: run periodically on `main`, it rewrites every matching record and
no-ops once they are all corrected — self-healing as new ones arrive.

Precise + conservative. A record is rewritten only when it carries all of a rule's
signals (its `agent≜…`, `provider≜claude`, and the rule's `model≜…` shape). This
leaves untouched (a) genuine LLM proofs by the same agents (e.g. `model≜sonnet`),
(b) `seedkit` template fixtures (`provider≜seedkit`), and (c) any other contributor
(e.g. the same `template-zmod-decide` shape under a different agent). Solver/credit
(`solver≜…`) is never changed — ranking is unaffected.

Usage:
  python3 -m tools.repo.relabel_attribution            # dry-run under . : count what changes
  python3 -m tools.repo.relabel_attribution --apply .  # rewrite the files under the given root
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Each rule: (agent, model-regex, honest provider, honest model). A claude-mislabelled
# record matching the agent + model shape is rewritten to the honest provider/model.
# Rules are agent-disjoint, so order does not matter; scoping each to its agent keeps
# an identical `model≜…` shape under any other contributor untouched.
_RULES = (
    # ohdearquant's mac-158f deterministic Python/sympy template engine (ADR-079).
    ("mac-158f", re.compile(r"model≜template-[^;}\s]*"), "python", "sympy"),
    # chat-bit-01's claude-web proofs: a pure Lean kernel `decide` over a finite ZMod.
    ("claude-web", re.compile(r"model≜template-zmod-decide(?=[;}\s])"), "lean", "decide"),
)
# Records carrying provenance that the leaderboard reads.
SCAN_GLOBS = (
    "library/index/*.aisp",
    "packages/unsorry-archive-*/library/index/*.aisp",
    "proof-runs/*.aisp",
)


def relabel_record(text: str) -> tuple[str, bool]:
    """Return (text, changed). Rewrites a claude-mislabelled deterministic-template
    record to its honest provider/model per ``_RULES``. Idempotent: an already-corrected
    record (no `provider≜claude`), or one matching no rule, is returned unchanged."""
    if "provider≜claude" not in text:
        return text, False
    for agent, model_re, provider, model in _RULES:
        if f"agent≜{agent}" in text and model_re.search(text):
            new = text.replace("provider≜claude", f"provider≜{provider}")
            new = model_re.sub(f"model≜{model}", new)
            return new, new != text
    return text, False


def _iter_files(root: Path):
    for pattern in SCAN_GLOBS:
        yield from root.glob(pattern)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.relabel_attribution",
        description="Relabel claude-mislabelled deterministic-template proofs to their honest provider/model.")
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
          f"(claude-mislabelled deterministic templates → honest provider/model)"
          f"{'' if args.apply else ' [DRY-RUN]'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
