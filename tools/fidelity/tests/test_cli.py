"""Tests for the `python3 -m tools.fidelity` CLI: exit codes and output shape."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys

from conftest import PAIRS_DIR, REPO_ROOT, VALID_TREE

TRANSLATION_ALPHA = VALID_TREE / "translations" / "nat-zero-add.agent-alpha.aisp"
GOAL_RECORD = VALID_TREE / "goals" / "nat-zero-add.aisp"

CANONICAL_LINE = "∀x₁∈ℕ:0+x₁≡x₁"
CANONICAL_SHA = hashlib.sha256(CANONICAL_LINE.encode("utf-8")).hexdigest()


def run_cli(*args: str, stdin: str | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "tools.fidelity", *args],
        cwd=REPO_ROOT,
        input=stdin,
        capture_output=True,
        text=True,
    )


# ── normalize ────────────────────────────────────────────────────────────────


def test_normalize_raw_statement() -> None:
    proc = run_cli("normalize", "∀n∈ℕ:0+n≡n")
    assert proc.returncode == 0
    assert proc.stdout.strip() == CANONICAL_LINE


def test_normalize_translation_record_path() -> None:
    proc = run_cli("normalize", str(TRANSLATION_ALPHA))
    assert proc.returncode == 0
    assert proc.stdout.strip() == CANONICAL_LINE


def test_normalize_stdin() -> None:
    proc = run_cli("normalize", "-", stdin="∀ m ∈ ℕ : 0 + m ≡ m\n")
    assert proc.returncode == 0
    assert proc.stdout.strip() == CANONICAL_LINE


def test_normalize_aisp_file_without_stmt_block_errors() -> None:
    proc = run_cli("normalize", str(GOAL_RECORD))
    assert proc.returncode == 2
    assert proc.stderr != ""


# ── sha ──────────────────────────────────────────────────────────────────────


def test_sha_of_raw_statement() -> None:
    proc = run_cli("sha", "∀n∈ℕ:0+n≡n")
    assert proc.returncode == 0
    assert proc.stdout.strip() == CANONICAL_SHA


def test_sha_of_translation_record() -> None:
    proc = run_cli("sha", str(TRANSLATION_ALPHA))
    assert proc.returncode == 0
    assert proc.stdout.strip() == CANONICAL_SHA


# ── diff ─────────────────────────────────────────────────────────────────────


def test_diff_match_exit_zero_and_message() -> None:
    proc = run_cli("diff", "∀n∈ℕ:0+n≡n", "∀m∈ℕ:0+m≡m")
    assert proc.returncode == 0
    assert proc.stdout.strip() == f"MATCH sha={CANONICAL_SHA}"


def test_diff_match_on_pair_files() -> None:
    a = PAIRS_DIR / "equivalent" / "01-a.txt"
    b = PAIRS_DIR / "equivalent" / "01-b.txt"
    proc = run_cli("diff", str(a), str(b))
    assert proc.returncode == 0
    assert proc.stdout.startswith("MATCH sha=")


def test_diff_mismatch_exit_one_with_pointer() -> None:
    proc = run_cli("diff", "∀n∈ℕ:0+n≡n", "∀n∈ℤ:0+n≡n")
    assert proc.returncode == 1
    out = proc.stdout
    assert "MISMATCH" in out
    # character-level pointer to the first divergence:
    # ∀(0) x(1) ₁(2) ∈(3) ℕ(4) — index 4, ℕ vs ℤ
    assert "char 4" in out
    assert "ℕ" in out and "ℤ" in out
    # both normalized lines are shown for the flagged-goal review
    assert "∀x₁∈ℕ:0+x₁≡x₁" in out
    assert "∀x₁∈ℤ:0+x₁≡x₁" in out


def test_diff_json_match_shape() -> None:
    proc = run_cli("diff", "--json", "∀n∈ℕ:0+n≡n", "∀m∈ℕ:0+m≡m")
    assert proc.returncode == 0
    payload = json.loads(proc.stdout)
    assert payload == {
        "match": True,
        "sha": CANONICAL_SHA,
        "normalized": CANONICAL_LINE,
    }


def test_diff_json_mismatch_shape() -> None:
    proc = run_cli("diff", "--json", "∀n∈ℕ:0+n≡n", "∀n∈ℤ:0+n≡n")
    assert proc.returncode == 1
    payload = json.loads(proc.stdout)
    assert payload["match"] is False
    assert payload["index"] == 4  # ∀(0) x(1) ₁(2) ∈(3) ℕ(4)
    for side, glyph in (("a", "ℕ"), ("b", "ℤ")):
        assert set(payload[side]) == {"normalized", "sha", "char"}
        assert payload[side]["char"] == glyph
        assert len(payload[side]["sha"]) == 64


def test_diff_json_mismatch_prefix_has_null_char() -> None:
    proc = run_cli("diff", "--json", "∀n∈ℕ:0+n≡n", "∀n∈ℕ:0+n≡n+1")
    assert proc.returncode == 1
    payload = json.loads(proc.stdout)
    assert payload["a"]["char"] is None  # a ends where b continues


# ── usage errors ─────────────────────────────────────────────────────────────


def test_missing_subcommand_is_usage_error() -> None:
    proc = run_cli()
    assert proc.returncode == 2


def test_missing_path_is_an_error_not_a_statement() -> None:
    proc = run_cli("normalize", "/nonexistent/translation.aisp")
    assert proc.returncode == 2
    assert proc.stderr != ""
