"""Relabel deterministic-template proofs to their honest provider/model, and
backfill seedkit fixture difficulty, on main.

Several deterministic, non-LLM proof pipelines recorded provenance the leaderboard
renders as LLM work, overstating model involvement:

* ohdearquant's `mac-158f` pipeline used a deterministic Python/sympy template
  engine recorded as `provider≜claude; model≜template-*`; the honest record is
  `provider≜python; model≜sympy` (ADR-079).
* seedkit fixtures — chat-bit-01's `claude-web` runs and the kit's own `seedkit`
  agent — are pure Lean kernel proofs (a finite `ZMod` `decide`, or an
  `induction; ring`) recorded as `provider≜claude`/`seedkit`;
  `model≜template-zmod-decide`/`template-induction-ring`. The honest record is
  `provider≜lean; model≜decide`/`ring` (ADR-086).

In addition, seedkit historically self-tagged its template goals at difficulty
3–5; the honest value under the sourcing rubric is `1` (a one-tactic `decide` /
fixed `induction; ring`). This sweep backfills those merged goal records to
`difficulty≜1` (ADR-087), identified by the goal's own proof provenance.

A one-shot PR cannot fix this against a live corpus (it conflicts and is always
incomplete as the pipelines keep producing). This is the idempotent **sweep**:
run periodically on `main`, it rewrites every matching record and no-ops once they
are corrected — self-healing as new ones arrive.

Precise + conservative. A provenance record is rewritten only when it carries a
rule's `agent≜…` + a non-honest `provider≜…` (`claude`/`seedkit`) + the rule's
`model≜…` shape, so genuine LLM proofs by the same agents (e.g. `model≜sonnet`)
and any other contributor's identical model shape stay untouched. A goal's
difficulty is corrected only when the goal's own proof index record carries a
seedkit signature. `solver≜` credit is never changed — ranking *by credit* is
unaffected; only difficulty-weighted points move, which is the point (ADR-087).

Usage:
  python3 -m tools.repo.relabel_attribution            # dry-run under . : count changes
  python3 -m tools.repo.relabel_attribution --apply .  # rewrite the files under the root
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Each rule: (agent, model-regex, honest provider, honest model). A record is
# rewritten when it carries the rule's `agent≜…` and `model≜…` shape and a
# non-honest provider; scoping each rule to its agent keeps an identical
# `model≜…` shape under any other contributor untouched. mac-158f is genuinely
# Python/sympy; the seedkit agents (claude-web, seedkit) are Lean.
_RULES = (
    ("mac-158f", re.compile(r"model≜template-[^;}\s]*"), "python", "sympy"),
    ("claude-web", re.compile(r"model≜template-zmod-decide(?=[;}\s])"), "lean", "decide"),
    ("claude-web", re.compile(r"model≜template-induction-ring(?=[;}\s])"), "lean", "ring"),
    ("seedkit", re.compile(r"model≜template-zmod-decide(?=[;}\s])"), "lean", "decide"),
    ("seedkit", re.compile(r"model≜template-induction-ring(?=[;}\s])"), "lean", "ring"),
)

# Providers that flag a deterministic engine mislabelled (`claude`) or
# bespoke-labelled (`seedkit`). Honest providers (lean/python) are left alone,
# which is what makes the sweep idempotent.
_REWRITABLE_PROVIDERS = ("claude", "seedkit")

# A seedkit fixture's proof index record, tolerant of pre- and post-relabel
# state: one of the kit's agents carrying either a template-* model or the
# already-relabelled Lean engine. Used to find which goals' difficulty to
# backfill (ADR-087).
_SEEDKIT_AGENTS = ("seedkit", "claude-web")
_SEEDKIT_MODELS_TEMPLATE = ("template-zmod-decide", "template-induction-ring")
_SEEDKIT_MODELS_HONEST = ("decide", "ring")

# Records carrying provenance that the leaderboard reads.
SCAN_GLOBS = (
    "library/index/*.aisp",
    "packages/unsorry-archive-*/library/index/*.aisp",
    "proof-runs/*.aisp",
)

_PROVIDER_RE = re.compile(r"provider≜([^;}\s]+)")
_AGENT_RE = re.compile(r"agent≜([^;}\s]+)")
_MODEL_RE = re.compile(r"model≜([^;}\s]+)")
_GOAL_RE = re.compile(r"goal≜([^;}\s]+)")
_DIFFICULTY_RE = re.compile(r"difficulty≜[2-5]\b")  # only the inflated 2..5


def relabel_record(text: str) -> tuple[str, bool]:
    """Return (text, changed). Rewrites a deterministic-template record to its
    honest provider/model per ``_RULES``. Idempotent: a record whose provider is
    already honest, or which matches no rule, is returned unchanged."""
    prov = _PROVIDER_RE.search(text)
    if prov is None or prov.group(1) not in _REWRITABLE_PROVIDERS:
        return text, False
    for agent, model_re, provider, model in _RULES:
        if f"agent≜{agent}" in text and model_re.search(text):
            new = _PROVIDER_RE.sub(f"provider≜{provider}", text, count=1)
            new = model_re.sub(f"model≜{model}", new)
            return new, new != text
    return text, False


def index_is_seedkit(text: str) -> bool:
    """True if a proof index/run record is a seedkit fixture — one of the kit's
    agents carrying a template-* model or the relabelled Lean engine (ADR-087)."""
    agent = _AGENT_RE.search(text)
    model = _MODEL_RE.search(text)
    if agent is None or model is None or agent.group(1) not in _SEEDKIT_AGENTS:
        return False
    m = model.group(1)
    if m in _SEEDKIT_MODELS_TEMPLATE:
        return True
    return m in _SEEDKIT_MODELS_HONEST and "provider≜lean" in text


def goal_of(text: str) -> str | None:
    """The ``goal≜<id>`` an index record addresses, or None."""
    m = _GOAL_RE.search(text)
    return m.group(1) if m else None


def correct_difficulty(text: str) -> tuple[str, bool]:
    """Return (text, changed). Rewrites an inflated ``difficulty≜2..5`` to
    ``difficulty≜1`` (ADR-087). Idempotent: ``difficulty≜0/1`` is unchanged. Only
    the difficulty digit changes — the statement, sha, and status are untouched."""
    new = _DIFFICULTY_RE.sub("difficulty≜1", text, count=1)
    return new, new != text


def _iter_files(root: Path):
    for pattern in SCAN_GLOBS:
        yield from root.glob(pattern)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="python3 -m tools.repo.relabel_attribution",
        description="Relabel deterministic-template proofs to honest provider/model "
                    "and backfill seedkit goal difficulty.")
    # Positional root, matching the repo's other path-scanning tools
    # (`tools.gate_b validate .`, `tools.leaderboard --check .`): the
    # attribution-relabel workflow invokes us as `… --apply .`, so the root
    # must be accepted positionally, not only via a flag.
    ap.add_argument("root", nargs="?", default=".",
                    help="repository root to scan (default: .)")
    ap.add_argument("--apply", action="store_true", help="rewrite files (default: dry-run)")
    args = ap.parse_args(argv)

    root = Path(args.root)

    # Pass A — relabel provenance, and collect the goals whose proof is a seedkit
    # fixture (read each record's current on-disk state, before any rewrite).
    prov_changed = 0
    seedkit_goals: set[str] = set()
    for path in _iter_files(root):
        text = path.read_text(encoding="utf-8")
        if index_is_seedkit(text):
            gid = goal_of(text)
            if gid:
                seedkit_goals.add(gid)
        new, did = relabel_record(text)
        if did:
            prov_changed += 1
            if args.apply:
                path.write_text(new, encoding="utf-8")

    # Pass B — backfill difficulty on exactly those seedkit goals (goals are
    # never archived, so one pass over goals/ fixes active + archived proofs).
    diff_changed = 0
    for gid in sorted(seedkit_goals):
        gp = root / "goals" / f"{gid}.aisp"
        if not gp.exists():
            continue
        gtext = gp.read_text(encoding="utf-8")
        gnew, gdid = correct_difficulty(gtext)
        if gdid:
            diff_changed += 1
            if args.apply:
                gp.write_text(gnew, encoding="utf-8")

    suffix = "" if args.apply else " [DRY-RUN]"
    print(f"attribution relabel: {'relabelled' if args.apply else 'would relabel'} "
          f"{prov_changed} record(s) (deterministic templates → honest provider/model)"
          f"{suffix}")
    print(f"seedkit difficulty backfill: {'corrected' if args.apply else 'would correct'} "
          f"{diff_changed} goal record(s) (inflated difficulty → 1){suffix}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
