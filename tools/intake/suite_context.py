"""Resolve a goal slug → its benchmark suite's verifier context (ADR-099 / SPEC-099-A §3).

`./swarm/run.sh --goal <slug>` must prove a benchmark goal **in the right context** —
the suite's own ``(toolchain, mathlib rev)`` — not the repo-wide pin. This module is the
slug→suite→pin resolver the swarm consults: given a goal id, it returns the suite that
owns it — the ``top`` sentinel, any obligation, **or a decomposition-descendant of either**
(ADR-116, so a benchmark obligation's sub-lemmas inherit its pin) — and that suite's
verifier context (toolchain, concrete mathlib rev, the ``_verify`` lake project, and its
lake lib target).

A slug that belongs to no registered suite resolves to ``None`` — the swarm keeps the
repo-pin path unchanged for organic goals. Pure + deterministic; reuses
``tools.leaderboard.registered_targets.suite_dirs`` (discovery) and
``tools.intake.verifier_context`` (the ``_verify`` dir + lake lib name), so there is one
source of truth for the suite layout.

CLI (the shell seam): ``python3 -m tools.intake.suite_context <goal> [--root .]`` prints a
single tab-separated line ``toolchain\\tmathlib\\tverify_dir\\tbuild_target`` when the goal
belongs to a suite, or nothing when it does not — both exit 0, so the caller branches on
whether the output is empty.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from tools.gate_b.graph import SUB_RE
from tools.gate_b.records import parse_record
from tools.intake.verifier_context import _camel, verifier_dir
from tools.leaderboard.registered_targets import suite_dirs


def _decomp_parent_map(root: Path) -> dict[str, str]:
    """Sub-goal id → parent-goal id, across every ``decompositions/*.aisp`` under ``root``.

    Built from the same decomposition records ``tools.gate_b`` parses (ADR-009): the
    ``⟦Ω:Decomp⟧`` ``parent`` field and the content-addressed ids of the ``⟦Σ:Subs⟧``
    block (``SUB_RE``). This is the inheritance edge that lets a benchmark obligation's
    decomposition sub-lemmas resolve to the obligation's suite context (ADR-116). First
    record wins for a given child (``setdefault``); decompose is append-only per ADR-009."""
    parent_of: dict[str, str] = {}
    directory = root / "decompositions"
    if not directory.is_dir():
        return parent_of
    for path in sorted(directory.glob("*.aisp")):
        record = parse_record(path.read_text("utf-8"))
        parent = record.fields.get("parent", "")
        subs = record.block("Σ")
        if not parent or subs is None:
            continue
        for m in SUB_RE.finditer(subs.body):
            parent_of.setdefault(m.group("id"), parent)
    return parent_of


def _lineage(parent_of: dict[str, str], goal: str) -> list[str]:
    """``goal`` and its decomposition ancestors, nearest first.

    Walks the sub→parent chain (ADR-009 keeps it a DAG within the depth cap). A ``seen``
    set makes termination unconditional even on malformed cyclic data, and the walk is
    additionally bounded by the number of edges — no acyclic chain can be longer."""
    chain = [goal]
    seen = {goal}
    cursor = goal
    while cursor in parent_of and len(chain) <= len(parent_of):
        parent = parent_of[cursor]
        if parent in seen:  # defensive: never loop, even if the graph is malformed
            break
        seen.add(parent)
        chain.append(parent)
        cursor = parent
    return chain


def goal_suite_context(root: Path, goal: str) -> dict | None:
    """The verifier context of the registered suite that owns ``goal``, or None.

    A goal is owned by suite *S* if it is *S*'s ``top`` sentinel, one of *S*'s
    ``skeleton.aisp`` ``⟦Σ⟧`` obligations, **or a decomposition-descendant of either**
    (ADR-116): a sub-lemma minted by decompose-on-failure inherits its benchmark parent's
    suite pin, so it proves and stages at the same toolchain+mathlib as the parent.
    Descendants of no obligation still resolve to None (the organic repo-pin path).

    Returns ``{suite, toolchain, mathlib, verify_dir, build_target}`` where ``verify_dir``
    is repo-relative (POSIX) and ``build_target`` is the suite's lake lib name (matching
    the lakefile ``tools.intake.verifier_context`` scaffolds)."""
    root = Path(root)
    lineage = _lineage(_decomp_parent_map(root), goal)
    for suite in suite_dirs(root):
        skeleton = parse_record((suite / "skeleton.aisp").read_text("utf-8"))
        top = skeleton.fields.get("top", "")
        block = skeleton.block("Σ")
        obligations = {m.group("id") for m in SUB_RE.finditer(block.body)} if block else set()
        if not any(g == top or g in obligations for g in lineage):
            continue
        suite_id = suite.name
        return {
            "suite": suite_id,
            "toolchain": skeleton.fields.get("toolchain", ""),
            "mathlib": skeleton.fields.get("mathlib", ""),
            "verify_dir": verifier_dir(root, suite_id).relative_to(root).as_posix(),
            "build_target": _camel(suite_id),
        }
    return None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m tools.intake.suite_context")
    parser.add_argument("goal", help="the goal id to resolve")
    parser.add_argument("--root", default=".")
    args = parser.parse_args(argv)
    ctx = goal_suite_context(Path(args.root), args.goal)
    if ctx is None:
        return 0  # not a benchmark goal — empty output, caller keeps the repo pin
    print("\t".join((ctx["toolchain"], ctx["mathlib"], ctx["verify_dir"], ctx["build_target"])))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
