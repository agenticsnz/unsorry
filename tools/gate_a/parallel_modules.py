"""Run Gate A's module-wide checks in bounded parallel chunks.

Usage:
  python3 -m tools.gate_a.parallel_modules audit --jobs 4 \
    --output axiom-report.json
  python3 -m tools.gate_a.parallel_modules replay --jobs 4
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Sequence


@dataclass(frozen=True)
class Command:
    argv: tuple[str, ...]
    label: str


Runner = Callable[..., subprocess.CompletedProcess[str]]


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
) -> int:
    library = module_names(root, "library")
    goals = module_names(root, "goals")
    if not library and not goals:
        print("no library or goal modules found", file=sys.stderr)
        return 2

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

    library_jobs = max(1, jobs // 2) if library and goals else jobs
    goal_jobs = jobs - library_jobs if library and goals else jobs
    commands = [
        Command(
            ("lake", "exe", "axiom_audit", *chunk),
            f"library audit chunk {index}",
        )
        for index, chunk in enumerate(split_evenly(library, library_jobs), 1)
    ]
    commands.extend(
        Command(
            ("lake", "exe", "axiom_audit", "--allow-sorry", *chunk),
            f"goal audit chunk {index}",
        )
        for index, chunk in enumerate(split_evenly(goals, goal_jobs), 1)
    )

    results = run_commands(commands, jobs, runner)
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
    print(
        f"audited {len(library)} library and {len(goals)} goal module(s) "
        f"in {len(commands)} chunk(s)"
    )
    return 0


def replay(root: Path, jobs: int, runner: Runner = subprocess.run) -> int:
    library = module_names(root, "library")
    if not library:
        print("no library modules found", file=sys.stderr)
        return 2
    # leanchecker re-checks every declaration against the kernel and holds
    # ~all of mathlib resident per process, so its memory cost is essentially
    # fixed regardless of how few library modules a chunk carries. Two
    # concurrent invocations therefore OOM-kill a standard CI runner (the
    # replay step died with exit 143 repo-wide after #264 set --jobs 4 — the
    # earlier min(jobs, 2) cap was not enough). Replay runs serially: one
    # leanchecker over the whole library, one mathlib image in memory. The
    # `jobs` argument is accepted for CLI symmetry with `audit` but ignored
    # here; audit (collectAxioms, far lighter) keeps its parallelism.
    _ = jobs
    replay_jobs = 1
    commands = [
        Command(
            ("lake", "env", "leanchecker", *chunk),
            f"kernel replay chunk {index}",
        )
        for index, chunk in enumerate(split_evenly(library, replay_jobs), 1)
    ]
    results = run_commands(commands, replay_jobs, runner)
    if report_failures(commands, results):
        return 1
    print(f"replayed {len(library)} library module(s) in {len(commands)} chunk(s)")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("audit", "replay"))
    parser.add_argument("--jobs", type=int, default=4)
    parser.add_argument("--output", type=Path, default=Path("axiom-report.json"))
    parser.add_argument("--root", type=Path, default=Path("."))
    args = parser.parse_args(argv)
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    if args.command == "audit":
        return audit(args.root, args.jobs, args.output)
    return replay(args.root, args.jobs)


if __name__ == "__main__":
    raise SystemExit(main())
