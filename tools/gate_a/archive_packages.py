"""Validate ADR-041 archive packages touched by a PR.

Archive packages live under ``packages/unsorry-archive-*``. They are separate
Lake packages, so active-library replay/audit scoping does not see their
``library/`` trees. This helper gives Gate A an explicit archive-boundary check.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Callable, Sequence

from tools.gate_a.parallel_modules import module_names

ARCHIVE_PREFIX = "packages/unsorry-archive-"
FORBIDDEN_RE = re.compile(
    r"\b(sorry|admit|sorryAx|native_decide|axiom|unsafe|implemented_by|extern)\b"
)

Runner = Callable[..., subprocess.CompletedProcess[str]]


def changed_paths(root: Path, base: str, runner: Runner = subprocess.run) -> list[str] | None:
    res = runner(
        ("git", "-C", str(root), "diff", "--name-only", base, "HEAD"),
        check=False,
        text=True,
        capture_output=True,
    )
    if res.returncode != 0:
        return None
    return [line.strip() for line in res.stdout.splitlines() if line.strip()]


def archive_root_for_path(root: Path, path: str) -> Path | None:
    parts = Path(path).parts
    if len(parts) < 2 or parts[0] != "packages":
        return None
    package = parts[1]
    if not package.startswith("unsorry-archive-"):
        return None
    return root / "packages" / package


def archive_roots_from_paths(root: Path, paths: Sequence[str]) -> list[Path]:
    roots = {archive_root for path in paths if (archive_root := archive_root_for_path(root, path))}
    return sorted(roots)


def archive_roots(root: Path) -> list[Path]:
    packages = root / "packages"
    if not packages.is_dir():
        return []
    return sorted(path for path in packages.glob("unsorry-archive-*") if path.is_dir())


def changed_archive_roots(
    root: Path, base: str | None, runner: Runner = subprocess.run
) -> list[Path] | None:
    if base is None:
        return archive_roots(root)
    paths = changed_paths(root, base, runner)
    if paths is None:
        return None
    return archive_roots_from_paths(root, paths)


def only_index_metadata_changed(package_rel: str, changed) -> bool:
    """True iff this package's changed files (vs base) are confined to
    ``library/index/*.aisp`` — proof modules, lakefile, toolchain and goals all
    untouched. Such a change (e.g. an attribution/provenance edit) cannot affect
    proof content or packaging, so the disk-heavy ``lake build`` is redundant given
    the ADR-048 provenance byte-identity guard already proves the modules unchanged.
    Returns False if the package has no changes (nothing to fast-path)."""
    prefix = f"{package_rel}/"
    index_prefix = f"{package_rel}/library/index/"
    in_pkg = [c for c in changed if c.startswith(prefix)]
    if not in_pkg:
        return False
    return all(c.startswith(index_prefix) and c.endswith(".aisp") for c in in_pkg)


def default_targets(package_root: Path) -> list[str]:
    lakefile = package_root / "lakefile.toml"
    if not lakefile.is_file():
        return []
    match = re.search(
        r"^defaultTargets\s*=\s*\[([^\]]*)\]",
        lakefile.read_text(encoding="utf-8"),
        re.MULTILINE,
    )
    if not match:
        return []
    return re.findall(r'"([^"]+)"', match.group(1))


def forbidden_tokens(package_root: Path) -> list[str]:
    findings: list[str] = []
    library = package_root / "library"
    if not library.is_dir():
        return findings
    for path in sorted(library.rglob("*.lean")):
        for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if FORBIDDEN_RE.search(line):
                findings.append(f"{path.relative_to(package_root)}:{line_no}: {line.strip()}")
    return findings


def run_step(
    label: str,
    argv: tuple[str, ...],
    *,
    cwd: Path,
    runner: Runner = subprocess.run,
) -> int:
    print(f"[archive] {label}: {' '.join(argv)}")
    result = runner(argv, cwd=str(cwd), check=False, text=True, capture_output=True)
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)
    if result.returncode != 0:
        print(f"[archive] {label} failed with exit code {result.returncode}", file=sys.stderr)
    return result.returncode


def _git_blob(repo_root: Path, ref_path: str, runner: Runner = subprocess.run) -> str | None:
    """Git blob hash (content hash) of ``ref:path``, or None if it doesn't exist."""
    res = runner(
        ("git", "-C", str(repo_root), "rev-parse", "--verify", "-q", ref_path),
        check=False,
        text=True,
        capture_output=True,
    )
    if res.returncode != 0:
        return None
    return res.stdout.strip() or None


def archive_proof_provenance(
    repo_root: Path,
    package_root: Path,
    base: str,
    runner: Runner = subprocess.run,
) -> int:
    """ADR-048: every tracked proof module in an archive package must be
    byte-identical (same git blob) to a previously *verified* version — either
    the base active module (`library/Unsorry/X.lean`, being archived now) or the
    base archived copy (already frozen). This is the bookkeeping guard that lets
    archive validation skip the kernel replay: it proves the archived file is
    exactly the artifact Gate A kernel-verified when it was active. Changed or
    net-new proof content in an archive (which was never replayed) is rejected.
    """
    rel = package_root.relative_to(repo_root).as_posix()
    ls = runner(
        ("git", "-C", str(repo_root), "ls-tree", "-r", "--name-only", "HEAD", "--", f"{rel}/library"),
        check=False,
        text=True,
        capture_output=True,
    )
    if ls.returncode != 0:
        print(f"[archive] {rel}: cannot list tracked archive proof modules", file=sys.stderr)
        return 1
    files = [f.strip() for f in ls.stdout.splitlines() if f.strip().endswith(".lean")]
    if not files:
        print(f"[archive] {rel}: no tracked archive proof modules to verify", file=sys.stderr)
        return 1
    bad: list[str] = []
    for f in files:
        head_blob = _git_blob(repo_root, f"HEAD:{f}", runner)
        active_path = f[len(rel) + 1 :]  # strip "packages/unsorry-archive-NNNN/"
        prior = {
            _git_blob(repo_root, f"{base}:{active_path}", runner),
            _git_blob(repo_root, f"{base}:{f}", runner),
        }
        prior.discard(None)
        if head_blob is None or head_blob not in prior:
            bad.append(f)
    if bad:
        print(
            f"[archive] {rel}: archived proof module(s) NOT byte-identical to a "
            f"verified prior version (ADR-048 provenance):",
            file=sys.stderr,
        )
        for f in bad:
            print(f"  {f}", file=sys.stderr)
        print(
            "  an archived proof must be exactly the artifact Gate A verified when it was "
            "active; changed/new proof content must land via an active proof PR first.",
            file=sys.stderr,
        )
        return 1
    print(f"[archive] {rel}: provenance OK — {len(files)} proof module(s) byte-identical to verified base")
    return 0


def _dependency_pins(root: Path) -> tuple[str, frozenset[tuple[str, str]]] | None:
    """(toolchain, {(dep name, rev)}) for a Lake project, or None if unreadable."""
    toolchain = root / "lean-toolchain"
    manifest = root / "lake-manifest.json"
    if not toolchain.is_file() or not manifest.is_file():
        return None
    try:
        packages = json.loads(manifest.read_text(encoding="utf-8")).get("packages", [])
        pins = frozenset(
            (str(p.get("name")), str(p.get("rev"))) for p in packages if p.get("name")
        )
    except (json.JSONDecodeError, AttributeError, TypeError):
        return None
    if not pins:
        return None
    return toolchain.read_text(encoding="utf-8").strip(), pins


def shareable_packages_dir(repo_root: Path, package_root: Path) -> Path | None:
    """The repo's own ``.lake/packages``, when this archive can safely reuse it.

    An archive package is a *snapshot* of the active repo (ADR-041), so it pins
    the same toolchain and the same dependency revisions. Building each one in
    its own Lake project therefore clones and builds an identical mathlib per
    package — with 134 archives that exhausts the runner disk long before the
    set is covered, which is what killed the first full-replay run ever to reach
    this step ("No space left on device", run 30520185283, #7209). The
    ``base``-driven fast-path above already documents the same hazard for wide
    metadata PRs (#3218); a base-less scheduled run has no fast-path and hits it
    unconditionally.

    Reuse is gated on an EXACT match of toolchain and every dependency pin. A
    toolchain bump splits the archive set from the active repo, and building an
    archive against a mathlib it was not verified with must never happen
    silently — on any mismatch this returns None and the package falls back to
    its own clone, which is slow but correct.
    """
    shared = repo_root / ".lake" / "packages"
    if not shared.is_dir():
        return None
    repo_pins = _dependency_pins(repo_root)
    archive_pins = _dependency_pins(package_root)
    if repo_pins is None or archive_pins is None or repo_pins != archive_pins:
        return None
    return shared


def _link_shared_tree(package_root: Path, shared: Path) -> Path | None:
    """Point the package's dependency dir at ``shared``. Returns the link made."""
    link = package_root / ".lake" / "packages"
    if link.exists() or link.is_symlink():
        return None  # a real tree (or link) is already there — leave it alone
    link.parent.mkdir(parents=True, exist_ok=True)
    link.symlink_to(shared, target_is_directory=True)
    return link


def _unlink_shared_tree(link: Path | None) -> None:
    """Remove the link only. Never recurse — the target is the repo's real tree."""
    if link is not None and link.is_symlink():
        link.unlink()


def validate_archive_package(
    repo_root: Path,
    package_root: Path,
    runner: Runner = subprocess.run,
    base: str | None = None,
) -> int:
    rel = package_root.relative_to(repo_root)
    if not (package_root / "lakefile.toml").is_file():
        print(f"[archive] {rel}: missing lakefile.toml", file=sys.stderr)
        return 1
    if not (package_root / "lean-toolchain").is_file():
        print(f"[archive] {rel}: missing lean-toolchain", file=sys.stderr)
        return 1
    modules = module_names(package_root, "library")
    if not modules:
        print(f"[archive] {rel}: no archive library modules", file=sys.stderr)
        return 1

    # ADR-048 provenance: prove each archived proof module is byte-identical to a
    # version Gate A already kernel-verified (base active / already-archived). This
    # is the load-bearing guard that licenses skipping the kernel replay below.
    # Requires a base ref (PR diff); a base-less push run trusts the PR that
    # introduced the package (immutable since), so it is skipped there.
    if base is not None:
        provenance = archive_proof_provenance(repo_root, package_root, base, runner)
        if provenance != 0:
            return provenance

    findings = forbidden_tokens(package_root)
    if findings:
        print(f"[archive] forbidden token(s) in {rel}/library:", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        return 1

    gate_b = run_step(
        f"{rel} Gate B metadata",
        (
            sys.executable,
            "-m",
            "tools.gate_b",
            "validate",
            str(rel),
            "--goals-root",
            str(rel),
        ),
        cwd=repo_root,
        runner=runner,
    )
    if gate_b != 0:
        return gate_b

    generate = run_step(
        f"{rel} statement bindings",
        (sys.executable, "-m", "tools.gate_a.check_statement_binding", "generate", str(rel)),
        cwd=repo_root,
        runner=runner,
    )
    if generate != 0:
        return generate

    # ADR-048 fast-path: a change confined to library/index/*.aisp (attribution /
    # provenance metadata) leaves every proof module, the lakefile, and the
    # toolchain byte-identical — the provenance guard above already proved it. The
    # lake build only re-checks packaging, which a metadata edit cannot break, and
    # rebuilding every changed package (each cloning mathlib) exhausts the runner
    # disk on a wide metadata PR (#3218). Skip the redundant build for such changes.
    if base is not None:
        changed_now = changed_paths(repo_root, base, runner) or []
        if only_index_metadata_changed(rel.as_posix(), changed_now):
            print(f"[archive] {rel}: index-metadata-only change — proof modules "
                  f"byte-identical (provenance OK), skipping redundant rebuild (ADR-048)")
            return 0

    modules = module_names(package_root, "library")
    targets = default_targets(package_root)
    build_argv = ("lake", "build", *targets, "--wfail") if targets else ("lake", "build", "--wfail")
    # #7209: reuse the repo's already-built dependency tree when the pins match
    # exactly, instead of cloning a private mathlib per package.
    shared = shareable_packages_dir(repo_root, package_root)
    link: Path | None = None
    try:
        if shared is not None:
            link = _link_shared_tree(package_root, shared)
        if link is not None:
            print(f"[archive] {rel}: sharing the repo dependency tree (pins match) — no mathlib fetch")
        else:
            cache = run_step(
                f"{rel} Mathlib cache", ("lake", "exe", "cache", "get"), cwd=package_root, runner=runner
            )
            if cache != 0:
                return cache
        build = run_step(f"{rel} Lake build", build_argv, cwd=package_root, runner=runner)
        if build != 0:
            return build
        # No leanchecker replay here (ADR-048, verify-on-ingest). These proofs were
        # kernel-replayed by Gate A when they were ACTIVE, and the provenance check
        # above (archive_proof_provenance) proves each archived proof MODULE is
        # byte-identical to that already-verified artifact — while goal statements
        # are pinned by ADR-018 in gate-a-prepare. Re-running leanchecker on the
        # same immutable proof re-proves nothing, and it loads the package's full
        # mathlib image, which OOM-killed even a 16 GB runner (#764). `lake build
        # --wfail` above stays as packaging sanity (an archive package is a new
        # Lake project, so confirm it still compiles cleanly).
    finally:
        _unlink_shared_tree(link)
        run_step(
            f"{rel} clean generated bindings",
            (sys.executable, "-m", "tools.gate_a.check_statement_binding", "clean", str(rel)),
            cwd=repo_root,
            runner=runner,
        )

    print(f"[archive] {rel}: validated {len(modules)} module(s)")
    return 0


def validate_changed(
    root: Path,
    base: str | None,
    runner: Runner = subprocess.run,
) -> int:
    roots = changed_archive_roots(root, base, runner)
    if roots is None:
        print("[archive] cannot compute changed archive packages; validating all archives")
        roots = archive_roots(root)
    if not roots:
        print("[archive] no changed archive packages")
        return 0
    for package_root in roots:
        result = validate_archive_package(root, package_root, runner, base=base)
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
