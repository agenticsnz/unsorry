"""Write-mode archive cut (ADR-041 / SPEC-041-A §8–§9).

The report-only planner (`tools.archive`) proposes a block; this performs the
mechanical cut the §8 runbook describes, baking in both hard-won invariants:

  (A) archive whole decomposition trees, never split one;
  (B) never touch generated docs (this tool moves only proof/goal/index/backlog/
      proof-run/decomposition artefacts under the block — it writes no docs/).

For each selected goal it MOVES the proof module, its `library/index/<sha>.aisp`,
`goals/<id>.lean`, `backlog/<id>.md`, and `proof-runs/<id>.*`; COPIES
`goals/<id>.aisp` into the package verbatim (provenance); and re-points the active
`goals/<id>.aisp` to the archived end-state (`status≜archived`, `src`/`lean`
prefixed with the package path, `sha` unchanged). Whole-tree decomposition records
move into the package. It writes the package `lakefile.toml`, `lean-toolchain`,
`lake-manifest.json`, and `archive-manifest.json`.

It does NOT run git or open a PR — that stays a deliberate human step (validate
with SPEC-041-A §8 step 5, then open the retire PR).
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
from pathlib import Path

from tools.archive.plan import (
    ARCHIVE_PREFIX,
    ARCHIVE_ROOT,
    DEFAULT_BLOCK_SIZE,
    ProvedGoal,
    archived_goal_ids,
    next_block_id,
    proved_goals,
)
from tools.gate_b.records import parse_record


def _camel(block_id: str) -> str:
    # unsorry-archive-0005 -> UnsorryArchive0005
    return "".join(p.capitalize() for p in block_id.split("-"))


def decomposition_components(root: Path) -> dict[str, frozenset[str]]:
    """Union-find over active decompositions/*.aisp: returns goal -> the set of
    all goals in its decomposition tree (transitive parent+subs). Goals in no
    decomposition are absent (standalone)."""
    parent: dict[str, str] = {}

    def find(x: str) -> str:
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a: str, b: str) -> None:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    decomp_dir = root / "decompositions"
    if decomp_dir.is_dir():
        for path in sorted(decomp_dir.glob("*.aisp")):
            rec = parse_record(path.read_text(encoding="utf-8"))
            p = rec.fields.get("parent")
            if not p:
                continue
            for key, val in rec.fields.items():
                # subs render as sub₁≜⟨id≜<goal>,sha≜…⟩ — pull the id
                m = re.search(r"id≜([^,⟩\s]+)", val) if isinstance(val, str) else None
                if key.startswith("sub") and m:
                    union(p, m.group(1))
    groups: dict[str, set[str]] = {}
    for node in list(parent):
        groups.setdefault(find(node), set()).add(node)
    out: dict[str, frozenset[str]] = {}
    for members in groups.values():
        fm = frozenset(members)
        for g in members:
            out[g] = fm
    return out


def select_block(root: Path, size: int) -> list[ProvedGoal]:
    """Tree-aware selection (invariant A): proved, not-yet-archived goals, taken in
    the planner's stable order, including a goal only when its whole decomposition
    component is also eligible; whole components are added atomically up to `size`."""
    archived = archived_goal_ids(root)

    def is_real_proof(goal: str) -> bool:
        # Skip seed/translate goals with no Lean artifact (lean≜∅) — they are not
        # archivable proof modules (e.g. nat-zero-lt-succ / Unsorry.Basic).
        rec = parse_record((root / "goals" / f"{goal}.aisp").read_text(encoding="utf-8"))
        return rec.fields.get("phase") == "prove" and rec.fields.get("lean") not in (None, "∅")

    eligible = [g for g in proved_goals(root)
                if g.goal not in archived and is_real_proof(g.goal)]
    eligible_ids = {g.goal for g in eligible}
    by_id = {g.goal: g for g in eligible}
    components = decomposition_components(root)

    selected: list[str] = []
    selected_set: set[str] = set()
    for g in eligible:
        if g.goal in selected_set:
            continue
        comp = components.get(g.goal)
        if comp is None:
            group = [g.goal]  # standalone
        else:
            if not comp <= eligible_ids:
                continue  # split tree — defer the whole component
            group = [m for m in comp if m in by_id]
        if selected and len(selected) + len(group) > size:
            continue  # keep trees whole; don't exceed the target by splitting
        for m in group:
            if m not in selected_set:
                selected.append(m)
                selected_set.add(m)
        if len(selected) >= size:
            break
    return [by_id[g] for g in selected]


def _move(root: Path, rel: str, pkg: Path) -> None:
    src = root / rel
    if not src.exists():
        return
    dst = pkg / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(src), str(dst))


def _retire_active_record(root: Path, goal: str, block_id: str) -> None:
    """Re-point the active goals/<id>.aisp to the archived end-state in place."""
    path = root / "goals" / f"{goal}.aisp"
    text = path.read_text(encoding="utf-8")
    text = text.replace("status≜archived", "status≜proved")  # idempotency guard
    text = re.sub(r"status≜proved", "status≜archived", text, count=1)
    prefix = f"{ARCHIVE_ROOT.as_posix()}/{block_id}/"

    def reprefix(m: re.Match) -> str:
        field, val = m.group(1), m.group(2)
        if val == "∅" or val.startswith(prefix):
            return m.group(0)  # never prefix the empty sentinel or double-prefix
        return f"{field}{prefix}{val}"

    text = re.sub(r"(src≜)(\S+)", reprefix, text, count=1)
    text = re.sub(r"(lean≜)(\S+)", reprefix, text, count=1)
    path.write_text(text, encoding="utf-8")


def cut(root: Path, size: int, source_commit: str, toolchain: str, mathlib: str) -> dict:
    block_id = next_block_id(root)
    goals = select_block(root, size)
    if not goals:
        raise SystemExit("no eligible whole-tree goals to archive")
    block_goals = {g.goal for g in goals}
    pkg = root / ARCHIVE_ROOT / block_id
    pkg.mkdir(parents=True, exist_ok=True)

    for g in goals:
        # COPY the goal record verbatim (provenance) before retiring the active one
        gp = root / "goals" / f"{g.goal}.aisp"
        (pkg / "goals").mkdir(parents=True, exist_ok=True)
        shutil.copy2(gp, pkg / "goals" / f"{g.goal}.aisp")
        # MOVE the artefacts
        _move(root, g.module_path, pkg)
        _move(root, g.index_path, pkg)
        _move(root, f"goals/{g.goal}.lean", pkg)
        _move(root, f"backlog/{g.goal}.md", pkg)
        for pr in g.proof_run_paths:
            _move(root, pr, pkg)
        # retire the active record
        _retire_active_record(root, g.goal, block_id)

    # MOVE whole-tree decomposition records whose parent is in the block
    decomp_dir = root / "decompositions"
    moved_decomps = 0
    if decomp_dir.is_dir():
        for path in sorted(decomp_dir.glob("*.aisp")):
            rec = parse_record(path.read_text(encoding="utf-8"))
            if rec.fields.get("parent") in block_goals:
                _move(root, f"decompositions/{path.name}", pkg)
                moved_decomps += 1

    camel = _camel(block_id)
    (pkg / "lakefile.toml").write_text(
        f'name = "{camel[0].lower() + camel[1:]}"\n'
        'version = "0.1.0"\n'
        'keywords = ["math", "archive", "unsorry"]\n'
        f'defaultTargets = ["{camel}"]\n\n'
        "[leanOptions]\n"
        "pp.unicode.fun = true\n"
        "autoImplicit = false\n"
        "relaxedAutoImplicit = false\n\n"
        "[[require]]\n"
        'name = "mathlib"\n'
        'scope = "leanprover-community"\n'
        f'rev = "{mathlib}"\n\n'
        "[[lean_lib]]\n"
        f'name = "{camel}"\n'
        'srcDir = "library"\n'
        'globs = ["Unsorry.+"]\n',
        encoding="utf-8",
    )
    (pkg / "lean-toolchain").write_text(
        (root / "lean-toolchain").read_text(encoding="utf-8"), encoding="utf-8"
    )
    # Reuse the most recent existing block's lake-manifest (same pins) as the
    # archive-package manifest; root's includes the goals package and differs.
    prior = sorted((root / ARCHIVE_ROOT).glob(f"{ARCHIVE_PREFIX}*/lake-manifest.json"))
    manifest_src = prior[-1] if prior else (root / "lake-manifest.json")
    shutil.copy2(manifest_src, pkg / "lake-manifest.json")

    manifest = {
        "block_id": block_id,
        "target_size": size,
        "proof_count": len(goals),
        "status": "frozen",
        "source_commit": source_commit,
        "validation_commit": None,
        "pins": {"lean_toolchain": toolchain, "mathlib": mathlib},
        "notes": [
            f"ADR-041 proof archive block {block_id.removeprefix(ARCHIVE_PREFIX)}.",
            "Whole decomposition trees + standalone proved goals only (invariant A).",
            "Active goal records remain as archived metadata pointing at this package.",
        ],
        "goals": [{"goal": g.goal, "module": g.module} for g in goals],
    }
    (pkg / "archive-manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    return {"block_id": block_id, "proof_count": len(goals),
            "decompositions": moved_decomps, "goals": sorted(block_goals)}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="python3 -m tools.archive.apply",
                                 description="Write-mode archive cut (ADR-041 §8).")
    ap.add_argument("--root", default=".")
    ap.add_argument("--size", type=int, default=DEFAULT_BLOCK_SIZE)
    ap.add_argument("--source-commit", required=True, help="git SHA of the cut base")
    ap.add_argument("--toolchain", required=True, help='e.g. leanprover/lean4:v4.30.0')
    ap.add_argument("--mathlib", required=True, help='e.g. v4.30.0')
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args(argv)
    result = cut(Path(args.root), args.size, args.source_commit,
                 args.toolchain, args.mathlib)
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"cut {result['block_id']}: {result['proof_count']} goals, "
              f"{result['decompositions']} decomposition records")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
