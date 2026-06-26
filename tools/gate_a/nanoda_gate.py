"""Gate A axiom-audit replacement via nanoda — ADR-097 / SPEC-097-A (Phase 3b).

Replaces the LIBRARY `axiom_audit` with a declaration-scoped `lean4export` + nanoda
check that enforces the same axiom whitelist (`unpermitted_axiom_hard_error`, so a
sneaked `sorryAx` fails) in ~seconds on one runner. The `leanchecker` `p=1` replay is
UNCHANGED — this is the axiom-footprint check only, not the kernel oracle.

Coverage (SPEC-097-A §2): it claims only the LEAF-proof case. `compute_audit_targets`
is the single source of truth for *what to audit*; when its mode is `full` (a non-leaf
/ global-impact / untrusted diff) this reports `covered=False` so the caller FALLS BACK
to the real `axiom_audit` (fail-closed). Goals (audited `--allow-sorry`) are out of
scope here and keep the real audit.

Exit codes (CLI): 0 covered+clean (gate pass) · 1 covered but a proof FAILED (gate fail)
· 2 NOT covered — caller must run the real audit · 3 tooling/usage error.
"""
from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import time
from pathlib import Path
from typing import Callable, Sequence

from tools.gate_a.parallel_modules import compute_audit_targets
from tools.independent_check import check_proof

Runner = Callable[..., subprocess.CompletedProcess]


def nanoda_gate(
    root: Path,
    base: str | None,
    lean4export_cmd: Sequence[str],
    nanoda_cmd: Sequence[str],
    export_dir: Path,
    runner: Runner = subprocess.run,
    clock: Callable[[], float] = time.perf_counter,
    timeout: float = 600.0,
) -> dict:
    """Run the nanoda audit-replacement over the PR's changed LIBRARY closure.

    Returns a result dict:
      covered=False               → mode 'full': caller must run the real audit;
      covered=True, ok=True        → every scoped library proof passed (gate pass);
      covered=True, ok=False       → at least one proof failed nanoda (gate fail).
    A module is a PASS iff nanoda status=='ok' AND target_confirmed (the positive
    control proved the theorem present, not a deps-only export), with the axiom
    whitelist hard-enforced."""
    scope = compute_audit_targets(root, base)
    if scope.mode == "full":
        return {
            "covered": False,
            "mode": "full",
            "reason": "non-leaf / global-impact / untrusted diff — real axiom_audit required",
            "modules": [],
        }
    results: list[dict] = []
    ok = True
    for module in scope.library:
        v = check_proof(
            root, module, lean4export_cmd, nanoda_cmd, export_dir,
            runner, clock, timeout, enforce_axioms=True,
        )
        results.append(v)
        if not (v.get("status") == "ok" and v.get("target_confirmed")):
            ok = False
    return {
        "covered": True,
        "ok": ok,
        "mode": scope.mode,
        "library_count": len(scope.library),
        "goal_count": len(scope.goals),
        "modules": results,
    }


def gate_exit_code(result: dict) -> int:
    """Pure: map a nanoda_gate result to the CLI exit code (see module docstring)."""
    if not result.get("covered"):
        return 2
    return 0 if result.get("ok") else 1


def render_summary(result: dict) -> str:
    """One compact human/CI summary line + per-failed-module detail."""
    if not result.get("covered"):
        return f"nanoda-gate: NOT COVERED ({result.get('reason')}) — falling back to real axiom_audit"
    n = result.get("library_count", 0)
    head = (
        f"nanoda-gate: {'PASS' if result.get('ok') else 'FAIL'} "
        f"({result.get('mode')}) — {n} library proof(s) axiom+kernel checked by nanoda"
    )
    if result.get("ok"):
        return head
    bad = [m for m in result.get("modules", [])
           if not (m.get("status") == "ok" and m.get("target_confirmed"))]
    lines = [head] + [
        f"  ✗ {m['module']}: status={m.get('status')} target={m.get('target_confirmed')} {m.get('stderr', '')}"
        for m in bad
    ]
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", type=Path, default=Path("."))
    p.add_argument("--base", default=None, help="git base SHA to diff against (None ⇒ full ⇒ not covered)")
    p.add_argument("--lean4export-cmd", default="lake env lean4export")
    p.add_argument("--nanoda-cmd", default="nanoda")
    p.add_argument("--export-dir", type=Path, default=Path("nanoda-gate-exports"))
    p.add_argument("--timeout", type=float, default=600.0)
    p.add_argument("--output-json", type=Path, default=None)
    args = p.parse_args(argv)

    result = nanoda_gate(
        args.root, args.base,
        shlex.split(args.lean4export_cmd), shlex.split(args.nanoda_cmd),
        args.export_dir, timeout=args.timeout,
    )
    summary = render_summary(result)
    print(summary, flush=True)
    sp = os.environ.get("GITHUB_STEP_SUMMARY")
    if sp:
        with Path(sp).open("a", encoding="utf-8") as h:
            h.write(f"### nanoda-gate (ADR-097)\n\n{summary}\n")
    if args.output_json:
        args.output_json.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return gate_exit_code(result)


if __name__ == "__main__":
    raise SystemExit(main())
