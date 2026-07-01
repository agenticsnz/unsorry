"""Re-pin pre-ADR-116 benchmark decomposition sub-lemmas to their suite pin.

Before ADR-116, decomposing a benchmark obligation minted its sub-lemmas as plain
repo goals, proved into the REPO library at the repo pin (`lean4:v4.30`/its mathlib)
— unusable for the parent's suite-pinned recompose (`_verify` sees neither the repo
library nor its Lean+mathlib). This one-time migration re-opens such subs so the
swarm re-proves them at the SUITE pin, where ADR-116 now routes them. Per sub:

  * ``goals/<sub>.aisp``                  status -> open, sha -> ∅ (unproved)
  * ``library/Unsorry/<Module>.lean``     removed (the repo-pin proof module)
  * ``library/index/<sha>.aisp``          removed (the repo-pin proof artifact)
  * ``proof-runs/<sub>.*.aisp`` (proved)  removed (they reference the artifact — GB020)

A sub is in scope iff it is a decomposition-descendant of a benchmark obligation
(``goal_suite_context`` resolves it, ADR-116) AND is currently proved at the repo pin
(has a ``library/index`` entry). ``--suite`` / ``--parent`` narrow the scope; the
default is a DRY RUN — pass ``--apply`` to write. Idempotent: a sub already re-opened
(no repo index entry) is simply skipped.

CLI: ``python3 -m tools.intake.remigrate_benchmark_subs --root . [--suite S | --parent P ...] [--apply]``
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

from tools.gate_b.graph import SUB_RE
from tools.gate_b.records import parse_record
from tools.intake.suite_context import goal_suite_context

# A proved index record maps a goal to its proof; the file name is the statement sha.
_INDEX_GOAL_RE = re.compile(r"goal≜([A-Za-z0-9-]+)")
_INDEX_NAME_RE = re.compile(r"name≜([A-Za-z0-9_']+)")
# `^theorem <name>` locates the declaring module (grandfathered lemmas are not
# always camel(goal), so we search by the proved theorem name — same as proved-deps).
_MODULE_DECL = "theorem {name}"


@dataclass
class SubPlan:
    """The migration actions for one repo-proved benchmark sub-lemma."""

    sub: str
    suite: str
    goal_path: Path
    index_path: Path
    module_path: Path | None
    proof_runs: list[Path] = field(default_factory=list)


def _repo_proved(root: Path) -> dict[str, tuple[str, str | None]]:
    """goal id -> (statement-sha, theorem-name) for every REPO-pin proof.

    The repo `library/index/<sha>.aisp` set is exactly the proofs at the repo pin;
    suite-pin proofs live under `targets/<suite>/_verify/library/index` and are never
    read here, so an already-re-pinned sub is absent and gets skipped."""
    out: dict[str, tuple[str, str | None]] = {}
    index_dir = root / "library" / "index"
    if not index_dir.is_dir():
        return out
    for path in sorted(index_dir.glob("*.aisp")):
        text = path.read_text("utf-8")
        g = _INDEX_GOAL_RE.search(text)
        if not g:
            continue
        n = _INDEX_NAME_RE.search(text)
        out[g.group(1)] = (path.stem, n.group(1) if n else None)
    return out


def _module_for(root: Path, name: str | None) -> Path | None:
    """The `library/Unsorry/<Module>.lean` declaring `theorem <name>`, or None."""
    if not name:
        return None
    decl = re.compile(rf"^theorem {re.escape(name)}\b", re.MULTILINE)
    for path in sorted((root / "library" / "Unsorry").glob("*.lean")):
        if decl.search(path.read_text("utf-8")):
            return path
    return None


def _proved_proof_runs(root: Path, sub: str) -> list[Path]:
    """`proof-runs/<sub>.*.aisp` records whose outcome is `proved` (they reference the
    now-removed index artifact — GB020). Failed/decomposed runs are lesson history and
    are kept."""
    runs_dir = root / "proof-runs"
    if not runs_dir.is_dir():
        return []
    hits = []
    for path in sorted(runs_dir.glob(f"{sub}.*.aisp")):
        if re.search(r"outcome≜proved\b", path.read_text("utf-8")):
            hits.append(path)
    return hits


def _benchmark_descendant_subs(root: Path) -> dict[str, str]:
    """Every decomposition sub id -> its resolved benchmark suite (ADR-116).

    A sub resolves via `goal_suite_context` (the top/obligation/descendant lineage).
    Organic subs (no suite) are omitted."""
    out: dict[str, str] = {}
    decomp_dir = root / "decompositions"
    if not decomp_dir.is_dir():
        return out
    for path in sorted(decomp_dir.glob("*.aisp")):
        for m in SUB_RE.finditer(path.read_text("utf-8")):
            sid = m.group("id")
            if sid in out:
                continue
            ctx = goal_suite_context(root, sid)
            if ctx:
                out[sid] = ctx["suite"]
    return out


def plan_migration(
    root: Path, *, suite: str | None = None, parents: set[str] | None = None
) -> list[SubPlan]:
    """The re-pin plan for the in-scope, repo-proved benchmark subs.

    ``suite`` filters to one suite id; ``parents`` (goal ids) filters to descendants of
    those parents (prefix match on the machine `<parent>-sN` convention). Both optional.
    """
    root = Path(root)
    proved = _repo_proved(root)
    plans: list[SubPlan] = []
    for sub, sub_suite in sorted(_benchmark_descendant_subs(root).items()):
        if suite is not None and sub_suite != suite:
            continue
        if parents is not None and not any(
            sub == p or sub.startswith(f"{p}-") for p in parents
        ):
            continue
        if sub not in proved:  # already re-pinned / never repo-proved — idempotent skip
            continue
        goal_path = root / "goals" / f"{sub}.aisp"
        if not goal_path.is_file():
            continue
        sha, name = proved[sub]
        plans.append(
            SubPlan(
                sub=sub,
                suite=sub_suite,
                goal_path=goal_path,
                index_path=root / "library" / "index" / f"{sha}.aisp",
                module_path=_module_for(root, name),
                proof_runs=_proved_proof_runs(root, sub),
            )
        )
    return plans


def reopen_goal(path: Path) -> None:
    """Set a template-rigid goal record to open + unproved: rewrite the single
    ``status≜`` line to ``open`` and the single ``sha≜`` line to ``∅`` (mirrors the
    harness's ``rewrite-goal`` so the record stays Gate-B-valid)."""
    lines = path.read_text("utf-8").splitlines(keepends=True)
    status_hits = sha_hits = 0
    out = []
    for line in lines:
        stripped = line.lstrip()
        indent = line[: len(line) - len(stripped)]
        nl = "\n" if line.endswith("\n") else ""
        if stripped.startswith("status≜"):
            status_hits += 1
            out.append(f"{indent}status≜open{nl}")
        elif stripped.startswith("sha≜"):
            sha_hits += 1
            out.append(f"{indent}sha≜∅{nl}")
        else:
            out.append(line)
    if status_hits != 1:
        raise ValueError(f"{path}: {status_hits} status≜ lines, expected 1")
    if sha_hits != 1:
        raise ValueError(f"{path}: {sha_hits} sha≜ lines, expected 1")
    path.write_text("".join(out), "utf-8")


def apply_plan(plans: list[SubPlan]) -> None:
    """Execute every plan: re-open the goal and remove its repo-pin proof artifacts."""
    for p in plans:
        reopen_goal(p.goal_path)
        p.index_path.unlink(missing_ok=True)
        if p.module_path is not None:
            p.module_path.unlink(missing_ok=True)
        for run in p.proof_runs:
            run.unlink(missing_ok=True)


def _format(plans: list[SubPlan]) -> str:
    if not plans:
        return "no repo-proved benchmark subs in scope — nothing to migrate"
    lines = []
    by_suite: dict[str, int] = {}
    for p in plans:
        by_suite[p.suite] = by_suite.get(p.suite, 0) + 1
        mod = p.module_path.name if p.module_path else "(module not found)"
        lines.append(
            f"  {p.sub} [{p.suite}]: reopen {p.goal_path.name}; "
            f"rm {mod}, {p.index_path.name}, {len(p.proof_runs)} proof-run(s)"
        )
    head = ", ".join(f"{n} in {s}" for s, n in sorted(by_suite.items()))
    return f"{len(plans)} sub(s) to re-pin ({head}):\n" + "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="python3 -m tools.intake.remigrate_benchmark_subs")
    ap.add_argument("--root", default=".")
    ap.add_argument("--suite", default=None, help="restrict to one suite id (e.g. putnam-v1)")
    ap.add_argument("--parent", action="append", default=None, help="restrict to a parent goal id (repeatable)")
    ap.add_argument("--apply", action="store_true", help="write the changes (default: dry run)")
    args = ap.parse_args(argv)
    plans = plan_migration(
        Path(args.root), suite=args.suite, parents=set(args.parent) if args.parent else None
    )
    print(_format(plans))
    if args.apply and plans:
        apply_plan(plans)
        print(f"applied: re-pinned {len(plans)} sub(s).")
    elif plans:
        print("(dry run — pass --apply to write)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
