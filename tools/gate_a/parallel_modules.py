"""Run Gate A's module-wide checks in bounded parallel chunks.

Usage:
  python3 -m tools.gate_a.parallel_modules audit --jobs 4 \
    --output axiom-report.json
  python3 -m tools.gate_a.parallel_modules audit --jobs 1 \
    --output axiom-report.json --base origin/main
  python3 -m tools.gate_a.parallel_modules replay --jobs 4
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Sequence

# Modules per serial leanchecker invocation in replay (ADR-006): bounds peak
# memory so the replay step does not OOM the runner as the library grows.
# Overridable via UNSORRY_REPLAY_CHUNK so a FULL replay can fit a smaller (8 GB)
# runner with a smaller chunk (ADR-048 Phase 2) — leanchecker holds ~all of
# mathlib resident per process, so a smaller chunk trims the few-olean peak and
# the wall-clock-per-chunk on a memory-bound runner. A missing or invalid value
# falls back to the safe 30-module default.
_DEFAULT_REPLAY_CHUNK_SIZE = 30


def _replay_chunk_size() -> int:
    raw = os.environ.get("UNSORRY_REPLAY_CHUNK")
    if raw is None:
        return _DEFAULT_REPLAY_CHUNK_SIZE
    try:
        value = int(raw)
    except ValueError:
        return _DEFAULT_REPLAY_CHUNK_SIZE
    return value if value >= 1 else _DEFAULT_REPLAY_CHUNK_SIZE


REPLAY_CHUNK_SIZE = _replay_chunk_size()

# Incremental replay (ADR-033): a FULL replay re-checks every olean against the
# kernel. An olean changes only with the proof source, the toolchain, or the
# dependency set — so only those force a full replay. A change to the python
# orchestration (`tools/gate_a/**`) or the CI workflow (`gate-a.yml`) does NOT
# change any olean, so it runs an INCREMENTAL replay (covering any changed
# library module; a no-op when none changed) rather than the memory-bound serial
# full replay that OOM-killed gate/CI PRs (ADR-047). The orchestration is covered
# by its own unit tests, and the push-to-main run is a full-replay backstop.
FULL_REPLAY_PATHS = frozenset(
    {"lean-toolchain", "lakefile.toml", "lakefile.lean", "lake-manifest.json"}
)
FULL_REPLAY_PREFIXES: tuple[str, ...] = ()
FULL_REPLAY_EXACT: tuple[str, ...] = ()
# The AUDIT is narrowed less: the auditor (`AxiomAudit/`), its fixtures, and its
# orchestration/whitelist (`tools/gate_a/**`) still force a full audit, since they
# can change which axioms the audit accepts. collectAxioms is light and parallel,
# so a full audit does not OOM the way a full replay does.
FULL_AUDIT_PREFIXES = ("tools/gate_a/", "AxiomAudit/", "AuditFixtures/")
FULL_AUDIT_EXACT = (".github/workflows/gate-a.yml",)

_IMPORT_RE = re.compile(r"^\s*import\s+(Unsorry\.[A-Za-z0-9_.]+)", re.MULTILINE)


@dataclass(frozen=True)
class Command:
    argv: tuple[str, ...]
    label: str


@dataclass(frozen=True)
class AuditScope:
    library: list[str]
    goals: list[str]
    mode: str


Runner = Callable[..., subprocess.CompletedProcess[str]]


def fmt_duration(seconds: float) -> str:
    """Human-friendly duration for CI logs and GitHub step summaries."""
    if seconds < 60:
        return f"{seconds:.1f}s"
    minutes, rest = divmod(seconds, 60)
    return f"{int(minutes)}m {rest:.1f}s"


def append_step_summary(title: str, rows: Sequence[tuple[str, object]]) -> None:
    """Append a compact metrics table to GITHUB_STEP_SUMMARY when running in CI."""
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not path:
        return
    with Path(path).open("a", encoding="utf-8") as handle:
        handle.write(f"\n### {title}\n\n")
        handle.write("| Metric | Value |\n")
        handle.write("| --- | --- |\n")
        for key, value in rows:
            handle.write(f"| {key} | {value} |\n")


def available_memory_gb() -> float:
    """Return available physical memory in GB, defaulting to a safe fallback on failure."""
    try:
        # On Linux / Proc filesystem (covers GHA standard runners)
        proc_mem = Path("/proc/meminfo")
        if proc_mem.is_file():
            for line in proc_mem.read_text().splitlines():
                if line.startswith("MemAvailable:"):
                    parts = line.split()
                    if len(parts) >= 2:
                        return float(parts[1]) / (1024 * 1024)
        # On macOS (Darwin)
        if sys.platform == "darwin":
            output = subprocess.check_output(["sysctl", "-n", "hw.memsize"], text=True)
            return float(output.strip()) / (1024 * 1024 * 1024)
    except Exception:
        pass
    return 4.0


def max_safe_jobs(requested_jobs: int) -> int:
    """Cap parallel jobs based on available RAM to prevent OOM kills (exit code 143)."""
    # Each concurrent Lean 4 compiler, audit, or replay process consumes ~3.5 GB of RAM.
    free_ram = available_memory_gb()
    safe_cap = max(1, int(free_ram // 3.5))
    return min(requested_jobs, safe_cap)


def module_names(root: Path, source_dir: str) -> list[str]:
    """Return Lean module names for every source below source_dir."""
    base = root / source_dir
    if not base.is_dir():
        return []
    modules = []
    for path in sorted(base.rglob("*.lean")):
        relative = path.relative_to(root if source_dir == "goals" else base)
        modules.append(".".join(relative.with_suffix("").parts))
    return modules


def split_evenly(items: Sequence[str], chunks: int) -> list[list[str]]:
    """Split items into non-empty, size-balanced contiguous chunks."""
    if not items:
        return []
    count = min(max(chunks, 1), len(items))
    quotient, remainder = divmod(len(items), count)
    result = []
    offset = 0
    for index in range(count):
        size = quotient + (1 if index < remainder else 0)
        result.append(list(items[offset:offset + size]))
        offset += size
    return result


def run_commands(
    commands: Sequence[Command],
    jobs: int,
    runner: Runner = subprocess.run,
) -> list[subprocess.CompletedProcess[str]]:
    def run_one(command: Command) -> subprocess.CompletedProcess[str]:
        return runner(
            command.argv,
            check=False,
            text=True,
            capture_output=True,
        )

    with ThreadPoolExecutor(max_workers=min(jobs, len(commands))) as executor:
        return list(executor.map(run_one, commands))


def report_failures(
    commands: Sequence[Command],
    results: Sequence[subprocess.CompletedProcess[str]],
) -> bool:
    failed = False
    for command, result in zip(commands, results, strict=True):
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        if result.returncode != 0:
            failed = True
            print(
                f"{command.label} failed with exit code {result.returncode}",
                file=sys.stderr,
            )
            if result.stdout:
                print(result.stdout, end="", file=sys.stderr)
    return failed


def audit(
    root: Path,
    jobs: int,
    output: Path,
    runner: Runner = subprocess.run,
    base: str | None = None,
) -> int:
    started = time.perf_counter()
    library = module_names(root, "library")
    goals = module_names(root, "goals")
    if not library and not goals:
        print("no library or goal modules found", file=sys.stderr)
        return 2

    scope = AuditScope(library, goals, "full")
    if base is not None:
        scoped = scoped_audit_targets(root, base, library, goals, runner)
        if scoped is None:
            pass  # reason already logged; full audit below
        else:
            scope = scoped
            print(
                f"incremental axiom audit: {len(scope.library)} of {len(library)} "
                f"library and {len(scope.goals)} of {len(goals)} goal module(s)"
            )
            if not scope.library and not scope.goals:
                output.write_text("[]\n", encoding="utf-8")
                elapsed = time.perf_counter() - started
                print("axiom audit: no changed library or goal modules — empty report")
                append_step_summary(
                    "Gate A axiom audit",
                    (
                        ("Scope", scope.mode),
                        ("Library modules", f"0 of {len(library)}"),
                        ("Goal modules", f"0 of {len(goals)}"),
                        ("Commands", 0),
                        ("Elapsed", fmt_duration(elapsed)),
                    ),
                )
                return 0

    build = runner(
        ("lake", "build", "axiom_audit"),
        check=False,
        text=True,
        capture_output=True,
    )
    if build.returncode != 0:
        print(build.stdout, end="", file=sys.stderr)
        print(build.stderr, end="", file=sys.stderr)
        return build.returncode

    # axiom_audit is memory-intensive as it loads large Mathlib environment;
    # dynamically limit parallelism based on available memory to prevent OOM kills.
    audit_jobs = max_safe_jobs(jobs)
    library_jobs = max(1, audit_jobs // 2) if scope.library and scope.goals else audit_jobs
    goal_jobs = audit_jobs - library_jobs if scope.library and scope.goals else audit_jobs
    commands = [
        Command(
            ("lake", "exe", "axiom_audit", *chunk),
            f"library audit chunk {index}",
        )
        for index, chunk in enumerate(split_evenly(scope.library, library_jobs), 1)
    ]
    commands.extend(
        Command(
            ("lake", "exe", "axiom_audit", "--allow-sorry", *chunk),
            f"goal audit chunk {index}",
        )
        for index, chunk in enumerate(split_evenly(scope.goals, goal_jobs), 1)
    )

    results = run_commands(commands, audit_jobs, runner)
    if report_failures(commands, results):
        return 1

    combined: list[dict[str, object]] = []
    for command, result in zip(commands, results, strict=True):
        try:
            report = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            print(f"{command.label} returned invalid JSON: {exc}", file=sys.stderr)
            return 1
        if not isinstance(report, list):
            print(f"{command.label} returned a non-array report", file=sys.stderr)
            return 1
        combined.extend(report)

    combined.sort(key=lambda item: str(item.get("decl", "")))
    output.write_text(json.dumps(combined, indent=2) + "\n", encoding="utf-8")
    elapsed = time.perf_counter() - started
    print(
        f"audited {len(scope.library)} library and {len(scope.goals)} goal module(s) "
        f"in {len(commands)} chunk(s) ({scope.mode}, {fmt_duration(elapsed)})"
    )
    append_step_summary(
        "Gate A axiom audit",
        (
            ("Scope", scope.mode),
            ("Library modules", f"{len(scope.library)} of {len(library)}"),
            ("Goal modules", f"{len(scope.goals)} of {len(goals)}"),
            ("Commands", len(commands)),
            ("Requested jobs", jobs),
            ("Effective jobs", audit_jobs),
            ("Elapsed", fmt_duration(elapsed)),
        ),
    )
    return 0


def library_module_for_path(path: str) -> str | None:
    """`library/Unsorry/Foo.lean` -> `Unsorry.Foo`; None if not a library Lean
    source. Matches module_names()'s library naming."""
    p = path.strip()
    if not (p.startswith("library/") and p.endswith(".lean")):
        return None
    return p[len("library/"):-len(".lean")].replace("/", ".")


def goal_module_for_path(path: str) -> str | None:
    """`goals/foo.lean` -> `goals.foo`; None if not a goal Lean source."""
    p = path.strip()
    if not (p.startswith("goals/") and p.endswith(".lean")):
        return None
    return p[:-len(".lean")].replace("/", ".")


def changed_paths(root: Path, base: str, runner: Runner = subprocess.run) -> list[str] | None:
    """Repo-relative paths changed between `base` and HEAD, or None if git can't
    answer (shallow clone missing base, not a repo, …) — the caller then does a
    FULL replay rather than trusting an empty diff."""
    res = runner(
        ("git", "-C", str(root), "diff", "--name-only", base, "HEAD"),
        check=False,
        text=True,
        capture_output=True,
    )
    if res.returncode != 0:
        return None
    return [line.strip() for line in res.stdout.splitlines() if line.strip()]


def forces_full_replay(paths: Sequence[str]) -> str | None:
    """Return the offending path if any change forces a full replay, else None."""
    for p in paths:
        if (
            p in FULL_REPLAY_PATHS
            or p in FULL_REPLAY_EXACT
            or any(p.startswith(prefix) for prefix in FULL_REPLAY_PREFIXES)
        ):
            return p
    return None


def forces_full_audit(paths: Sequence[str]) -> str | None:
    """Return the offending path if an audit run must cover every module."""
    for p in paths:
        if (
            p in FULL_REPLAY_PATHS
            or p in FULL_AUDIT_EXACT
            or any(p.startswith(prefix) for prefix in FULL_AUDIT_PREFIXES)
        ):
            return p
    return None


def import_graph(root: Path) -> dict[str, set[str]]:
    """Map each on-disk library module to the set of `Unsorry.*` modules it
    imports (parsed from `import` lines)."""
    base = root / "library"
    graph: dict[str, set[str]] = {}
    if not base.is_dir():
        return graph
    for path in sorted(base.rglob("*.lean")):
        module = ".".join(path.relative_to(base).with_suffix("").parts)
        text = path.read_text(encoding="utf-8", errors="replace")
        graph[module] = set(_IMPORT_RE.findall(text))
    return graph


def replay_scope(changed_modules: Sequence[str], graph: dict[str, set[str]]) -> list[str]:
    """The replay set: every changed module plus the transitive *reverse*-import
    closure (every on-disk module that imports, directly or transitively, a
    changed module). A module outside this set has an unchanged source AND only
    depends on unchanged modules, so its rebuilt olean is byte-identical to the
    one already kernel-replayed on `main` (ADR-033). Generated `*Binding` modules
    `import Unsorry.<Base>`, so a changed base pulls its binding in here too.
    Intersected with `graph` so deleted modules (no olean to check) drop out."""
    importers: dict[str, set[str]] = {}
    for module, imports in graph.items():
        for imported in imports:
            importers.setdefault(imported, set()).add(module)
    seen: set[str] = set()
    stack = list(changed_modules)
    while stack:
        module = stack.pop()
        if module in seen:
            continue
        seen.add(module)
        stack.extend(importers.get(module, ()))
    return sorted(seen & set(graph))


def scoped_targets(
    root: Path, base: str, runner: Runner = subprocess.run
) -> list[str] | None:
    """Modules to replay for an incremental run, or None to fall back to FULL
    replay (git unavailable, or a global-impact change). An empty list means
    "no library change — nothing to replay"."""
    paths = changed_paths(root, base, runner)
    if paths is None:
        print(
            f"incremental replay: cannot diff against {base!r} — FULL replay",
            file=sys.stderr,
        )
        return None
    offender = forces_full_replay(paths)
    if offender is not None:
        print(
            f"incremental replay: global-impact change {offender!r} — FULL replay",
            file=sys.stderr,
        )
        return None
    changed = [m for m in (library_module_for_path(p) for p in paths) if m]
    if not changed:
        return []
    return replay_scope(changed, import_graph(root))


def scoped_audit_targets(
    root: Path,
    base: str,
    library: Sequence[str],
    goals: Sequence[str],
    runner: Runner = subprocess.run,
) -> AuditScope | None:
    """Modules to axiom-audit for an incremental PR run.

    Returns None when the diff cannot be trusted or a gate/tooling change means
    the audit itself must be exercised against the full repository.
    """
    paths = changed_paths(root, base, runner)
    if paths is None:
        print(
            f"incremental axiom audit: cannot diff against {base!r} — FULL audit",
            file=sys.stderr,
        )
        return None
    offender = forces_full_audit(paths)
    if offender is not None:
        print(
            f"incremental axiom audit: global-impact change {offender!r} — FULL audit",
            file=sys.stderr,
        )
        return None

    changed_library = [m for m in (library_module_for_path(p) for p in paths) if m]
    changed_goals = [m for m in (goal_module_for_path(p) for p in paths) if m]
    library_set = set(library)
    goal_set = set(goals)
    scoped_library = replay_scope(changed_library, import_graph(root)) if changed_library else []
    scoped_goals = sorted(set(changed_goals) & goal_set)
    return AuditScope(
        sorted(set(scoped_library) & library_set),
        scoped_goals,
        "incremental",
    )


def compute_replay_targets(
    root: Path, base: str | None, runner: Runner = subprocess.run
) -> tuple[list[str], str]:
    """The modules a kernel replay must cover, with its mode:

    - ``("…", "full")``        — ``base`` is None, or the diff is untrusted /
      global-impact, so the FULL on-disk library is replayed (fail-closed: an
      unscopeable base never yields an empty set).
    - ``("…", "incremental")`` — ``base`` given and scoped to the changed +
      reverse-import closure (ADR-033).
    - ``([], "none")``         — ``base`` given and no library module changed.

    This is the single source of truth for *what to replay*; the serial
    ``replay`` and the sharded ``plan`` / ``replay_shard`` all read it, so a
    shard can never check a different set than a full replay would (the
    soundness coverage invariant, ADR-048/049/063)."""
    library = module_names(root, "library")
    if base is None:
        return library, "full"
    scoped = scoped_targets(root, base, runner)
    if scoped is None:
        return library, "full"  # untrusted/global-impact diff — fail-closed to FULL
    if not scoped:
        return [], "none"
    return scoped, "incremental"


def _replay_chunk_commands(targets: Sequence[str]) -> list[Command]:
    """Serial leanchecker commands over ``targets``, chunked to bound peak memory
    (one mathlib image per process; UNSORRY_REPLAY_CHUNK). split_evenly keeps the
    chunks disjoint and covering, so every target is replayed exactly once."""
    chunk_size = _replay_chunk_size()
    n_chunks = max(1, (len(targets) + chunk_size - 1) // chunk_size)
    return [
        Command(
            ("lake", "env", "leanchecker", *chunk),
            f"kernel replay chunk {index}/{n_chunks}",
        )
        for index, chunk in enumerate(split_evenly(targets, n_chunks), 1)
    ]


def replay(
    root: Path,
    jobs: int,
    runner: Runner = subprocess.run,
    base: str | None = None,
) -> int:
    started = time.perf_counter()
    library = module_names(root, "library")
    if not library:
        print("no library modules found", file=sys.stderr)
        return 2

    # Incremental replay (ADR-033): when a PR base is supplied, replay only the
    # changed library modules and their reverse-import closure; the rest are
    # byte-identical to (and already verified on) main. Falls back to FULL replay
    # whenever the incremental assumption cannot be trusted.
    targets, mode = compute_replay_targets(root, base, runner)
    if mode == "none":
        print("kernel replay: no changed library modules — nothing to verify")
        return 0
    if mode == "incremental":
        print(
            f"incremental kernel replay: {len(targets)} of {len(library)} "
            "module(s) (changed + reverse-import closure)"
        )
    # leanchecker re-checks every declaration against the kernel and holds
    # ~all of mathlib resident per process, so its memory cost is essentially
    # fixed regardless of how few library modules a chunk carries. Two
    # concurrent invocations therefore OOM-kill a standard CI runner (the
    # replay step died with exit 143 repo-wide after #264 set --jobs 4 — the
    # earlier min(jobs, 2) cap was not enough). Replay runs serially: one
    # leanchecker over the whole library, one mathlib image in memory. The
    # `jobs` argument is accepted for CLI symmetry with `audit` but ignored
    # here; audit (collectAxioms, far lighter) keeps its parallelism. Cross-
    # *runner* parallelism is the sharded path (plan / replay_shard, ADR-063).
    _ = jobs
    effective_jobs = 1
    commands = _replay_chunk_commands(targets)
    # parallelism 1: chunks run one after another, never concurrently.
    results = run_commands(commands, effective_jobs, runner)
    if report_failures(commands, results):
        return 1
    elapsed = time.perf_counter() - started
    print(
        f"replayed {len(targets)} library module(s) serially in {len(commands)} "
        f"chunk(s) ({fmt_duration(elapsed)}; requested jobs {jobs}, effective jobs {effective_jobs})"
    )
    append_step_summary(
        "Gate A kernel replay",
        (
            ("Library modules", f"{len(targets)} of {len(library)}"),
            ("Chunks", len(commands)),
            ("Requested jobs", jobs),
            ("Effective jobs", effective_jobs),
            ("Elapsed", fmt_duration(elapsed)),
        ),
    )
    return 0


def plan_shards(
    root: Path, shards: int, base: str | None, runner: Runner = subprocess.run
) -> dict[str, object]:
    """Plan a sharded kernel replay (ADR-063): compute the replay target set and
    how many disjoint shards it splits into. Emits `{shards, count, mode}` where
    `shards` is the matrix index list `[0, 1, …, effective-1]` and `effective =
    min(shards, len(targets))`. `count == 0` (no library change) yields an empty
    matrix so the matrix job is skipped. Each replay_shard re-derives its own
    slice from the same target set + the same shard count, so no module list is
    passed between jobs (only the git SHA is shared — keeping leanchecker's input
    locally-derived, the ADR-049 invariant)."""
    targets, mode = compute_replay_targets(root, base, runner)
    effective = min(max(shards, 1), len(targets)) if targets else 0
    return {"shards": list(range(effective)), "count": len(targets), "mode": mode}


def replay_shard(
    root: Path,
    shard_index: int,
    shard_total: int,
    runner: Runner = subprocess.run,
    base: str | None = None,
) -> int:
    """Kernel-replay one shard of the target set (ADR-063). The targets are
    recomputed from source (same SHA → identical set) and partitioned by
    split_evenly into `shard_total` disjoint, covering slices; this checks slice
    `shard_index`. Every module lands in exactly one shard, so across all shards
    each olean is kernel-replayed exactly once — the same guarantee a single
    serial replay gives. An out-of-range index (the set split into fewer slices
    than the configured shard count) is a no-op, not an error."""
    started = time.perf_counter()
    targets, mode = compute_replay_targets(root, base, runner)
    if not targets:
        print(f"kernel replay shard {shard_index}: nothing to verify ({mode})")
        return 0
    parts = split_evenly(targets, shard_total)
    if not 0 <= shard_index < len(parts):
        print(
            f"kernel replay shard {shard_index}: out of range "
            f"({len(parts)} shard(s) for {len(targets)} module(s)) — empty"
        )
        return 0
    shard_targets = parts[shard_index]
    commands = _replay_chunk_commands(shard_targets)
    results = run_commands(commands, 1, runner)  # serial: one leanchecker at a time
    if report_failures(commands, results):
        return 1
    elapsed = time.perf_counter() - started
    print(
        f"replayed shard {shard_index + 1}/{len(parts)}: {len(shard_targets)} "
        f"module(s) in {len(commands)} chunk(s) ({mode}, {fmt_duration(elapsed)})"
    )
    append_step_summary(
        "Gate A kernel replay (shard)",
        (
            ("Shard", f"{shard_index + 1} of {len(parts)}"),
            ("Modules", f"{len(shard_targets)} of {len(targets)}"),
            ("Chunks", len(commands)),
            ("Scope", mode),
            ("Elapsed", fmt_duration(elapsed)),
        ),
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("audit", "replay", "plan", "replay-shard"))
    parser.add_argument("--jobs", type=int, default=4)
    parser.add_argument("--output", type=Path, default=Path("axiom-report.json"))
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument(
        "--shards",
        type=int,
        default=8,
        help="plan: max parallel replay shards (capped at the module count).",
    )
    parser.add_argument(
        "--shard-index",
        type=int,
        default=0,
        help="replay-shard: which shard (0-based) of --shard-total to replay.",
    )
    parser.add_argument(
        "--shard-total",
        type=int,
        default=1,
        help="replay-shard: total shard count (must equal plan's --shards).",
    )
    parser.add_argument(
        "--base",
        default=None,
        help="PR base ref/sha. For replay, checks just the changed library "
        "modules and their reverse-import closure (ADR-033). For audit, checks "
        "the changed library closure plus changed goals. Omit for full checks "
        "(the post-merge backstop on main).",
    )
    args = parser.parse_args(argv)
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    if args.command == "audit":
        return audit(args.root, args.jobs, args.output, base=args.base)
    if args.command == "replay":
        return replay(args.root, args.jobs, base=args.base)
    if args.command == "plan":
        if args.shards < 1:
            parser.error("--shards must be positive")
        print(json.dumps(plan_shards(args.root, args.shards, args.base)))
        return 0
    # replay-shard
    if args.shard_total < 1:
        parser.error("--shard-total must be positive")
    return replay_shard(
        args.root, args.shard_index, args.shard_total, base=args.base
    )


if __name__ == "__main__":
    raise SystemExit(main())
