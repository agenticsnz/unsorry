import subprocess
import sys
from pathlib import Path

from tools.gate_a.archive_packages import (
    archive_proof_provenance,
    archive_roots_from_paths,
    changed_archive_roots,
    default_targets,
    forbidden_tokens,
    only_index_metadata_changed,
    validate_archive_package,
    validate_changed,
)


def test_metadata_only_change_detected():
    pkg = "packages/unsorry-archive-0007"
    assert only_index_metadata_changed(pkg, [
        f"{pkg}/library/index/aaa.aisp",
        f"{pkg}/library/index/bbb.aisp",
    ]) is True


def test_proof_or_packaging_change_blocks_fast_path():
    pkg = "packages/unsorry-archive-0007"
    assert only_index_metadata_changed(pkg, [
        f"{pkg}/library/index/aaa.aisp",
        f"{pkg}/library/Unsorry/Foo.lean",
    ]) is False
    assert only_index_metadata_changed(pkg, [f"{pkg}/lakefile.toml"]) is False
    assert only_index_metadata_changed(pkg, [f"{pkg}/library/index/aaa.json"]) is False


def test_no_changes_in_package_is_not_fast_path():
    pkg = "packages/unsorry-archive-0007"
    assert only_index_metadata_changed(pkg, [
        "packages/unsorry-archive-0008/library/index/aaa.aisp",
    ]) is False
    assert only_index_metadata_changed(pkg, []) is False


def _git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ("git", "-C", str(repo), *args), check=True, text=True, capture_output=True
    ).stdout.strip()


def _init_repo(repo: Path) -> None:
    _git(repo, "init", "-q")
    _git(repo, "config", "user.email", "t@t.t")
    _git(repo, "config", "user.name", "t")
    _git(repo, "config", "commit.gpgsign", "false")


def completed(
    argv: tuple[str, ...],
    returncode: int = 0,
    stdout: str = "",
    stderr: str = "",
) -> subprocess.CompletedProcess[str]:
    return subprocess.CompletedProcess(argv, returncode, stdout, stderr)


def _archive(root: Path) -> Path:
    package = root / "packages" / "unsorry-archive-0001"
    (package / "library" / "Unsorry").mkdir(parents=True)
    (package / "goals").mkdir()
    (package / "library" / "Unsorry" / "One.lean").write_text(
        "import Mathlib\n\ntheorem one : True := trivial\n",
        encoding="utf-8",
    )
    (package / "lakefile.toml").write_text(
        'defaultTargets = ["UnsorryArchive0001"]\n',
        encoding="utf-8",
    )
    (package / "lean-toolchain").write_text("leanprover/lean4:v4.30.0\n", encoding="utf-8")
    return package


def test_archive_roots_from_paths(tmp_path: Path):
    assert archive_roots_from_paths(
        tmp_path,
        [
            "packages/unsorry-archive-0001/library/Unsorry/Foo.lean",
            "packages/unsorry-archive-0001/archive-manifest.json",
            "packages/not-an-archive/file",
            "library/Unsorry/Foo.lean",
        ],
    ) == [tmp_path / "packages" / "unsorry-archive-0001"]


def test_changed_archive_roots_from_git_diff(tmp_path: Path):
    def runner(argv, **_kwargs):
        argv = tuple(argv)
        if argv[0] == "git":
            return completed(
                argv,
                stdout="packages/unsorry-archive-0002/library/Unsorry/A.lean\nREADME.md\n",
            )
        raise AssertionError(argv)

    assert changed_archive_roots(tmp_path, "origin/main", runner) == [
        tmp_path / "packages" / "unsorry-archive-0002"
    ]


def test_changed_archive_roots_git_failure_fails_closed(tmp_path: Path):
    def runner(argv, **_kwargs):
        return completed(tuple(argv), returncode=128)

    assert changed_archive_roots(tmp_path, "missing-base", runner) is None


def test_default_targets(tmp_path: Path):
    package = _archive(tmp_path)
    assert default_targets(package) == ["UnsorryArchive0001"]


def test_forbidden_tokens_scan_archive_library(tmp_path: Path):
    package = _archive(tmp_path)
    (package / "library" / "Unsorry" / "Bad.lean").write_text(
        "axiom bad : False\n",
        encoding="utf-8",
    )
    assert forbidden_tokens(package) == ["library/Unsorry/Bad.lean:1: axiom bad : False"]


def test_validate_archive_package_runs_soundness_steps(tmp_path: Path):
    package = _archive(tmp_path)
    calls: list[tuple[tuple[str, ...], str]] = []

    def runner(argv, **kwargs):
        argv = tuple(argv)
        calls.append((argv, kwargs.get("cwd", "")))
        if argv[:3] == (sys.executable, "-m", "tools.gate_a.check_statement_binding"):
            if argv[3] == "generate":
                (package / "library" / "Unsorry" / "OneBinding.lean").write_text(
                    "import Unsorry.One\n\ntheorem one_binding_check : True := one\n",
                    encoding="utf-8",
                )
            elif argv[3] == "clean":
                (package / "library" / "Unsorry" / "OneBinding.lean").unlink(missing_ok=True)
        return completed(argv)

    assert validate_archive_package(tmp_path, package, runner) == 0

    argv_only = [call[0] for call in calls]
    assert (
        sys.executable,
        "-m",
        "tools.gate_b",
        "validate",
        "packages/unsorry-archive-0001",
        "--goals-root",
        "packages/unsorry-archive-0001",
    ) in argv_only
    assert ("lake", "exe", "cache", "get") in argv_only
    assert ("lake", "build", "UnsorryArchive0001", "--wfail") in argv_only
    # ADR-048 (verify-on-ingest): archive validation does NOT re-run leanchecker —
    # the proofs were kernel-replayed when active and are byte-identical now.
    assert not any(c[:3] == ("lake", "env", "leanchecker") for c in argv_only)


def test_validate_archive_package_does_not_replay(tmp_path: Path):
    # ADR-048 (verify-on-ingest): an archive package — even a large one — is NOT
    # leanchecker-replayed. The proofs were kernel-verified when active and are
    # byte-identical now; re-replay re-proves nothing and OOM'd the runner (#764).
    # Validation is packaging sanity (lake build --wfail) + provenance, not
    # re-verification.
    package = tmp_path / "packages" / "unsorry-archive-0001"
    (package / "library" / "Unsorry").mkdir(parents=True)
    (package / "goals").mkdir()
    names = [f"M{i}" for i in range(40)]
    for n in names:
        (package / "library" / "Unsorry" / f"{n}.lean").write_text(
            "import Mathlib\n\ntheorem t : True := trivial\n", encoding="utf-8"
        )
    (package / "lakefile.toml").write_text(
        'defaultTargets = ["UnsorryArchive0001"]\n', encoding="utf-8"
    )
    (package / "lean-toolchain").write_text("leanprover/lean4:v4.30.0\n", encoding="utf-8")

    calls: list[tuple[str, ...]] = []

    def runner(argv, **_kwargs):
        argv = tuple(argv)
        calls.append(argv)
        return completed(argv)

    assert validate_archive_package(tmp_path, package, runner) == 0

    assert not any(c[:3] == ("lake", "env", "leanchecker") for c in calls)  # never replays
    assert ("lake", "build", "UnsorryArchive0001", "--wfail") in calls  # packaging sanity kept


def test_validate_changed_no_archive_changes_is_noop(tmp_path: Path):
    def runner(argv, **_kwargs):
        argv = tuple(argv)
        if argv[0] == "git":
            return completed(argv, stdout="README.md\n")
        raise AssertionError(argv)

    assert validate_changed(tmp_path, "origin/main", runner) == 0


def _archive_provenance_repo(tmp_path: Path) -> tuple[Path, str]:
    """A real git repo: base commit has the active proof; HEAD has it archived
    byte-identically into a package. Returns (repo, base_sha)."""
    repo = tmp_path
    _init_repo(repo)
    (repo / "library" / "Unsorry").mkdir(parents=True)
    proof = "import Mathlib\n\ntheorem one : True := trivial\n"
    (repo / "library" / "Unsorry" / "One.lean").write_text(proof, encoding="utf-8")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "active proof")
    base = _git(repo, "rev-parse", "HEAD")
    # archive move: delete active, add byte-identical copy under the package
    (repo / "library" / "Unsorry" / "One.lean").unlink()
    pkg = repo / "packages" / "unsorry-archive-0001" / "library" / "Unsorry"
    pkg.mkdir(parents=True)
    (pkg / "One.lean").write_text(proof, encoding="utf-8")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "archive 0001")
    return repo, base


def test_archive_provenance_accepts_byte_identical_move(tmp_path: Path):
    repo, base = _archive_provenance_repo(tmp_path)
    package = repo / "packages" / "unsorry-archive-0001"
    assert archive_proof_provenance(repo, package, base) == 0


def test_archive_provenance_rejects_tampered_proof(tmp_path: Path):
    # ADR-048 guard: archived proof bytes differ from the verified active version
    # (goal statement could be unchanged) -> must be rejected, since we no longer
    # kernel-replay archives.
    repo, base = _archive_provenance_repo(tmp_path)
    package = repo / "packages" / "unsorry-archive-0001"
    (package / "library" / "Unsorry" / "One.lean").write_text(
        "import Mathlib\n\ntheorem one : True := sorry\n", encoding="utf-8"
    )
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "tamper")
    assert archive_proof_provenance(repo, package, base) == 1


def test_archive_provenance_rejects_net_new_proof(tmp_path: Path):
    # A proof that never existed active (no base counterpart) cannot appear in an
    # archive — it was never kernel-verified.
    repo, base = _archive_provenance_repo(tmp_path)
    package = repo / "packages" / "unsorry-archive-0001"
    pkg = package / "library" / "Unsorry"
    (pkg / "Sneaky.lean").write_text(
        "import Mathlib\n\ntheorem sneaky : True := trivial\n", encoding="utf-8"
    )
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "net-new")
    assert archive_proof_provenance(repo, package, base) == 1
