"""Validate benchmark suite verification packages at the suite's mathlib pin
(ADR-099 / SPEC-099-A §2).

A benchmark suite is authored against its *own* mathlib pin, so its discharged
obligations cannot land in the repo ``UnsorryLibrary`` (which is one pin). They live
in a suite-scoped verification package at ``targets/<suite>/_verify`` — a self-contained
Lake project pinned to the suite's ``(toolchain, mathlib rev)`` (scaffolded by
``tools.intake.verifier_context``).

Unlike ADR-041 archive packages — whose proofs are byte-identical to an already-
*verified* active version, so archive validation may skip the kernel replay — benchmark
proofs were **never active** in the repo and so have no provenance shortcut: each must
be **kernel-verified here**, at the suite's pin:

  ``lake exe cache get``  (the suite pin's FRO binary cache)
  ``lake build --wfail``  (the kernel type-checks the proof; ``--wfail`` rejects the
                           ``sorry`` warning) + a source forbidden-token scan.

This is the segregated ``cohort:benchmark`` verified track: "0 false positives
(kernel-verified)" holds at the suite's pin (ADR-048/049 — the Lean kernel is the sole
sound oracle at *any* mathlib version; the rev only affects which statements elaborate).

Reuses the shared archive-package helpers (``run_step`` / ``forbidden_tokens`` /
``default_targets`` / ``changed_paths``) rather than duplicating the build/cache logic.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from tools.gate_a.archive_packages import (
    Runner,
    changed_paths,
    default_targets,
    forbidden_tokens,
    run_step,
)
from tools.gate_a.parallel_modules import module_names

#: The suite-scoped verifier-context dir name (matches tools.intake.verifier_context).
VERIFY_DIRNAME = "_verify"


def benchmark_verify_roots(root: Path) -> list[Path]:
    """Every scaffolded suite verification package — ``targets/<suite>/_verify`` dirs
    that carry a ``lakefile.toml``. Empty when ``targets/`` is absent."""
    targets = Path(root) / "targets"
    if not targets.is_dir():
        return []
    return sorted(
        p / VERIFY_DIRNAME
        for p in targets.iterdir()
        if p.is_dir() and (p / VERIFY_DIRNAME / "lakefile.toml").is_file()
    )


def verify_root_for_path(root: Path, path: str) -> Path | None:
    """The suite ``_verify`` root a changed ``targets/<suite>/_verify/...`` path belongs
    to, or None for a path outside any scaffolded verification package."""
    parts = Path(path).parts
    if len(parts) < 3 or parts[0] != "targets" or parts[2] != VERIFY_DIRNAME:
        return None
    vr = root / "targets" / parts[1] / VERIFY_DIRNAME
    return vr if (vr / "lakefile.toml").is_file() else None


def changed_benchmark_roots(
    root: Path, base: str | None, runner: Runner = subprocess.run
) -> list[Path] | None:
    if base is None:
        return benchmark_verify_roots(root)
    paths = changed_paths(root, base, runner)
    if paths is None:
        return None
    roots = {vr for path in paths if (vr := verify_root_for_path(root, path))}
    return sorted(roots)


def validate_benchmark_package(
    repo_root: Path,
    package_root: Path,
    runner: Runner = subprocess.run,
    base: str | None = None,
) -> int:
    """Kernel-verify one suite's discharged obligations at its own pin."""
    rel = package_root.relative_to(repo_root)
    if not (package_root / "lakefile.toml").is_file():
        print(f"[benchmark] {rel}: missing lakefile.toml", file=sys.stderr)
        return 1
    if not (package_root / "lean-toolchain").is_file():
        print(f"[benchmark] {rel}: missing lean-toolchain", file=sys.stderr)
        return 1

    modules = module_names(package_root, "library")
    if not modules:
        # An open suite has no discharged obligations yet — nothing to kernel-verify.
        print(f"[benchmark] {rel}: no proof modules yet (open suite) — nothing to verify")
        return 0

    findings = forbidden_tokens(package_root)
    if findings:
        print(f"[benchmark] forbidden token(s) in {rel}/library:", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        return 1

    targets = default_targets(package_root)
    build_argv = ("lake", "build", *targets, "--wfail") if targets else ("lake", "build", "--wfail")
    cache = run_step(f"{rel} Mathlib cache", ("lake", "exe", "cache", "get"), cwd=package_root, runner=runner)
    if cache != 0:
        return cache
    build = run_step(f"{rel} kernel build", build_argv, cwd=package_root, runner=runner)
    if build != 0:
        return build

    print(f"[benchmark] {rel}: kernel-verified {len(modules)} proof module(s) at the suite pin")
    return 0


def validate_changed(
    root: Path,
    base: str | None,
    runner: Runner = subprocess.run,
) -> int:
    roots = changed_benchmark_roots(root, base, runner)
    if roots is None:
        print("[benchmark] cannot compute changed suites; validating all benchmark packages")
        roots = benchmark_verify_roots(root)
    if not roots:
        print("[benchmark] no changed benchmark verification packages")
        return 0
    for package_root in roots:
        result = validate_benchmark_package(root, package_root, runner, base=base)
        if result != 0:
            return result
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("validate-changed",))
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--base", default=None)
    args = parser.parse_args(argv)
    root = args.root.resolve()
    if args.command == "validate-changed":
        return validate_changed(root, args.base)
    raise AssertionError(args.command)


if __name__ == "__main__":
    raise SystemExit(main())
