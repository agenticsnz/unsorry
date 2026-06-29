"""registered-targets.json generator + cohort segregation (ADR-092 / SPEC-092-A).

Reads the curated benchmark targets under ``targets/<suite>/`` and emits the
machine-readable *intent* surface the unsorry-guild goals page consumes,
``docs/metrics/registered-targets.json``. Also exposes :func:`benchmark_goal_ids` —
the set of goal ids belonging to a registered benchmark target — so the leaderboard's
organic passes EXCLUDE benchmark discharges (cohort segregation, the load-bearing
ADR-092 invariant).

Pure, stdlib-only, deterministic (``sort_keys=True``, no timestamps so ``--check``
does not churn). Every reader is a **no-op when ``targets/`` is absent** (the case
before any suite is imported), so wiring :func:`benchmark_goal_ids` into
``load_dataset`` leaves organic stats byte-identical until a suite actually lands.

A ``targets/<suite>/`` package carries (consistent with SPEC-081-A `skeleton-validate`):
- ``skeleton.aisp`` — manifest fields ``top``/``supplier``/``domain``/``mathlib``, a
  ``⟦Σ:Subs⟧`` obligation list, and an optional ``⟦Κ:Credit⟧{<id>≜credited|glue}`` map
  (the ADR-078 check-7 classification the importer records).
- ``target.aisp`` (optional suite metadata) — ``license``/``cohort`` and a registry
  ``domain``.
- the obligations themselves as top-level ``goals/<id>.{aisp,lean}`` (so the swarm,
  Gate A and the organic leaderboard consume them unchanged).
"""
from __future__ import annotations

import json
import re
from math import comb
from pathlib import Path

from tools.gate_b.graph import SUB_RE
from tools.gate_b.records import parse_record

SCHEMA_VERSION = 1
DEFAULT_COHORT = "benchmark"
DEFAULT_LICENSE = "UNKNOWN"

_GOAL_RE = re.compile(r"goal≜([A-Za-z0-9][A-Za-z0-9-]*)")
_DIFFICULTY_RE = re.compile(r"difficulty≜(\d+)")


def registered_targets_path(root: Path) -> Path:
    return Path(root) / "docs" / "metrics" / "registered-targets.json"


def suite_dirs(root: Path) -> list[Path]:
    """The registered benchmark suites — directories under ``targets/`` carrying a
    ``skeleton.aisp``. Empty when ``targets/`` does not exist."""
    targets = Path(root) / "targets"
    if not targets.is_dir():
        return []
    return sorted(
        p for p in targets.iterdir() if p.is_dir() and (p / "skeleton.aisp").is_file()
    )


def _obligation_ids(skeleton) -> list[str]:
    block = skeleton.block("Σ")
    return [m.group("id") for m in SUB_RE.finditer(block.body)] if block else []


def _credit_map(skeleton) -> dict[str, str]:
    block = skeleton.block("Κ")
    if block is None:
        return {}
    from tools.gate_b.records import parse_fields

    return parse_fields(block.body)


def benchmark_goal_ids(root: Path) -> set[str]:
    """All goal ids that belong to a registered benchmark target (the ``top``
    sentinel and every obligation), including suites marked ``retired`` — their
    immutable goals must stay segregated, never re-counted as organic. The
    leaderboard excludes these from organic credit. Empty when no suite is
    registered."""
    ids: set[str] = set()
    for suite in suite_dirs(root):
        skeleton = parse_record((suite / "skeleton.aisp").read_text("utf-8"))
        top = skeleton.fields.get("top")
        if top:
            ids.add(top)
        ids.update(_obligation_ids(skeleton))
    return ids


def _proved_goal_ids(root: Path) -> set[str]:
    """Goal ids with a proof in ``library/index`` (mirrors
    ``tools.sourcing.targets_board._proved`` — scan for ``goal≜<id>`` markers)."""
    proved: set[str] = set()
    indices = [Path(root) / "library" / "index"]
    packages = Path(root) / "packages"
    if packages.is_dir():
        indices.extend(sorted(packages.glob("unsorry-archive-*/library/index")))
    # Benchmark obligations proved at a non-repo pin land in the suite's verification
    # package, not the repo library (ADR-099 / SPEC-099-A §2): count those as proved too,
    # so a suite's proved-at-pin tally surfaces in registered-targets.json.
    targets = Path(root) / "targets"
    if targets.is_dir():
        indices.extend(sorted(targets.glob("*/_verify/library/index")))
    for index in indices:
        if index.is_dir():
            for entry in index.glob("*.aisp"):
                match = _GOAL_RE.search(entry.read_text(encoding="utf-8"))
                if match:
                    proved.add(match.group(1))
    return proved


def _difficulty(root: Path, goal_id: str) -> int:
    # Benchmark obligations live at benchmark-goals/<id>.aisp (ADR-110); organic goals at
    # goals/<id>.aisp. Read whichever exists.
    for sub in ("goals", "benchmark-goals"):
        path = Path(root) / sub / f"{goal_id}.aisp"
        if path.is_file():
            match = _DIFFICULTY_RE.search(path.read_text(encoding="utf-8"))
            return int(match.group(1)) if match else 0
    return 0


def pass_at_k(n: int, c: int, k: int) -> float:
    """Unbiased pass@k estimator ``1 − C(n−c, k)/C(n, k)`` (Codex/HumanEval): the
    probability that at least one of ``k`` samples drawn from ``n`` attempts is
    kernel-accepted, given ``c`` of the ``n`` were accepted."""
    if k <= 0 or n <= 0 or k > n:
        return 0.0
    if c <= 0:
        return 0.0
    if n - c < k:
        return 1.0
    return 1.0 - comb(n - c, k) / comb(n, k)


def suite_payload(root: Path, suite: Path, proved: set[str], stats: dict | None = None) -> dict:
    skeleton = parse_record((suite / "skeleton.aisp").read_text("utf-8"))
    meta: dict[str, str] = {}
    target = suite / "target.aisp"
    if target.is_file():
        meta = parse_record(target.read_text("utf-8")).fields

    credit = _credit_map(skeleton)
    obligations = _obligation_ids(skeleton)

    goals = []
    n_credited = n_glue = n_proved = 0
    for goal_id in obligations:
        kind = credit.get(goal_id, "credited")
        is_proved = goal_id in proved
        if kind == "glue":
            n_glue += 1
        else:
            n_credited += 1
        if is_proved:
            n_proved += 1
        goals.append(
            {
                "id": goal_id,
                "difficulty": _difficulty(root, goal_id),
                "status": "proved" if is_proved else "open",
                "credit": kind,
                "run_snippet": f"./swarm/run.sh --goal {goal_id}",
            }
        )

    top = skeleton.fields.get("top", "")
    return {
        "id": suite.name,
        "top": top,  # the suite sentinel — run the WHOLE suite with one goal id
        "run_snippet": f"./swarm/run.sh --goal {top}" if top else "",
        "domain": meta.get("domain") or skeleton.fields.get("domain", ""),
        "supplier": skeleton.fields.get("supplier", ""),
        "mathlib_pin": skeleton.fields.get("mathlib", ""),
        "license": meta.get("license", DEFAULT_LICENSE),
        "cohort": meta.get("cohort", DEFAULT_COHORT),
        "credited": n_credited,
        "glue": n_glue,
        "proved": n_proved,
        "pass_at": {},  # populated once per-attempt sampling lands (SPEC-092-A §2)
        "stats": stats if stats is not None else {},  # run summary (best/worst/pass-rate)
        "goals": sorted(goals, key=lambda g: g["id"]),
    }


def retired_packages(root: Path) -> set[str]:
    """Packages marked ``retired`` in the governance registry
    (``docs/governance/admitted-domains.json``). A retired suite has served its
    purpose (e.g. the demo smoke test): its goals are **immutable** (ADR-018) and
    stay benchmark-cohort — so ``benchmark_goal_ids`` still counts them and they
    never leak into the organic board — but it is dropped from the published intent
    surface so the guild stops listing it. Empty when the registry is absent."""
    registry = Path(root) / "docs" / "governance" / "admitted-domains.json"
    if not registry.is_file():
        return set()
    data = json.loads(registry.read_text(encoding="utf-8"))
    return {t["package"] for t in data.get("targets", []) if t.get("retired")}


def registered_targets(root: Path) -> dict:
    from tools.leaderboard.benchmark_runs import EMPTY_STATS, suite_run_stats  # lazy

    proved = _proved_goal_ids(root)
    retired = retired_packages(root)
    all_stats = suite_run_stats(root)
    suites = [
        suite_payload(root, suite, proved, all_stats.get(suite.name, EMPTY_STATS))
        for suite in suite_dirs(root)
        if suite.name not in retired
    ]
    return {"schema_version": SCHEMA_VERSION, "suites": suites}


def render_registered_targets_json(root: Path) -> str:
    return (
        json.dumps(registered_targets(root), ensure_ascii=False, indent=2, sort_keys=True)
        + "\n"
    )
