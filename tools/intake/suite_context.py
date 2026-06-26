"""Resolve a goal slug → its benchmark suite's verifier context (ADR-099 / SPEC-099-A §3).

`./swarm/run.sh --goal <slug>` must prove a benchmark goal **in the right context** —
the suite's own ``(toolchain, mathlib rev)`` — not the repo-wide pin. This module is the
slug→suite→pin resolver the swarm consults: given a goal id, it returns the suite that
owns it (the ``top`` sentinel or any obligation) and that suite's verifier context
(toolchain, concrete mathlib rev, the ``_verify`` lake project, and its lake lib target).

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


def goal_suite_context(root: Path, goal: str) -> dict | None:
    """The verifier context of the registered suite that owns ``goal``, or None.

    Returns ``{suite, toolchain, mathlib, verify_dir, build_target}`` where ``verify_dir``
    is repo-relative (POSIX) and ``build_target`` is the suite's lake lib name (matching
    the lakefile ``tools.intake.verifier_context`` scaffolds)."""
    root = Path(root)
    for suite in suite_dirs(root):
        skeleton = parse_record((suite / "skeleton.aisp").read_text("utf-8"))
        top = skeleton.fields.get("top", "")
        block = skeleton.block("Σ")
        obligations = {m.group("id") for m in SUB_RE.finditer(block.body)} if block else set()
        if goal != top and goal not in obligations:
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
