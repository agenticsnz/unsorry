"""Tests for the statement-fidelity normalizer (SPEC-003-C §Normalization).

Acceptance criteria (SPEC-003-C):
  * every planted equivalent pair normalizes byte-identical;
  * every planted distinct pair does not;
  * normalization is idempotent and deterministic;
  * the worked example from valid_tree hashes to the sha committed in its
    goal record (covered in test_extract.py as well).
"""

from __future__ import annotations

import pytest

from conftest import PAIRS_DIR, pair_ids, read_pair
from tools.fidelity.normalize import first_divergence, normalize, statement_sha
from tools.fidelity.symbols import CANONICAL, apply_symbol_table

EQUIVALENT = PAIRS_DIR / "equivalent"
DISTINCT = PAIRS_DIR / "distinct"

ALL_SIDES = sorted(
    str(p.relative_to(PAIRS_DIR)) for p in PAIRS_DIR.glob("*/*.txt")
)


# ── planted pairs ────────────────────────────────────────────────────────────


def test_minimum_pair_counts() -> None:
    assert len(pair_ids(EQUIVALENT)) >= 8
    assert len(pair_ids(DISTINCT)) >= 6


@pytest.mark.parametrize("pair_id", pair_ids(EQUIVALENT))
def test_equivalent_pairs_normalize_identical(pair_id: str) -> None:
    a, b = read_pair(EQUIVALENT, pair_id)
    assert normalize(a) == normalize(b)
    assert statement_sha(a) == statement_sha(b)


@pytest.mark.parametrize("pair_id", pair_ids(DISTINCT))
def test_distinct_pairs_normalize_differently(pair_id: str) -> None:
    a, b = read_pair(DISTINCT, pair_id)
    assert normalize(a) != normalize(b)
    assert statement_sha(a) != statement_sha(b)


# ── idempotence and determinism ──────────────────────────────────────────────


@pytest.mark.parametrize("side", ALL_SIDES)
def test_idempotence(side: str) -> None:
    raw = (PAIRS_DIR / side).read_text(encoding="utf-8")
    once = normalize(raw)
    assert normalize(once) == once


@pytest.mark.parametrize("side", ALL_SIDES)
def test_determinism(side: str) -> None:
    raw = (PAIRS_DIR / side).read_text(encoding="utf-8")
    assert normalize(raw) == normalize(raw)


def test_output_is_single_line_without_whitespace() -> None:
    out = normalize("∀ n ∈ ℕ :\n  0 + n ≡ n\n")
    assert "\n" not in out
    assert not any(ch.isspace() for ch in out)


# ── exact normal forms (pin the canonical output, not just pair agreement) ──


def test_worked_example_exact_form() -> None:
    assert normalize("∀n∈ℕ:0+n≡n") == "∀x₁∈ℕ:0+x₁≡x₁"


def test_worked_example_sha_matches_goal_record() -> None:
    assert (
        statement_sha("∀n∈ℕ:0+n≡n")
        == "73026be938ddd22261b6c55a2a5843465916f04559e06406d91b71b414b797a8"
    )


def test_library_index_sha_matches_filename() -> None:
    # library/index/<sha>.aisp in valid_tree is keyed by the normalized stmt.
    assert (
        statement_sha("∀x₁∈ℕ:0<x₁+1")
        == "464ef57ab509beba93c01c02bfab4ddeb157675c3d8df8c253e353ab5c09f262"
    )


def test_multi_var_binder() -> None:
    assert normalize("∀a,b∈ℕ:a+b≡b+a") == "∀x₁,x₂∈ℕ:x₁+x₂≡x₂+x₁"


def test_lambda_binder() -> None:
    assert normalize("λa,b.a+b") == "λx₁,x₂.x₁+x₂"


def test_exists_unique_binder() -> None:
    assert normalize("∃!n:n≡0") == "∃!x₁:x₁≡0"


def test_shadowing_scope() -> None:
    # Inner binder of the same name shadows: each gets its own fresh name.
    # (The outer body wrap is stripped by step 5 — it spans the whole binder
    # body to end-of-statement, which the binder scope covers anyway.)
    assert normalize("∀x:(P(x)∧∃x:Q(x))") == "∀x₁:P(x₁)∧∃x₂:Q(x₂)"


def test_free_identifiers_untouched() -> None:
    assert normalize("∀n∈ℕ:succ(n)∈ℕ") == "∀x₁∈ℕ:succ(x₁)∈ℕ"


def test_free_occurrence_before_binder_is_not_captured() -> None:
    # `n` left of the quantifier is free; only the bound occurrences rename.
    assert normalize("0<n∧∀n∈ℕ:0+n≡n") == "0<n∧∀x₁∈ℕ:0+x₁≡x₁"


def test_binder_scope_ends_at_group_close() -> None:
    # x bound only inside the parens; trailing x is free.
    assert normalize("(∀x∈ℕ:P(x))∧Q(x)") == "(∀x₁∈ℕ:P(x₁))∧Q(x)"


def test_set_expression_can_reference_outer_binding() -> None:
    assert normalize("∀n∈ℕ:∀m∈S(n):m∈S(n)") == "∀x₁∈ℕ:∀x₂∈S(x₁):x₂∈S(x₁)"


def test_already_canonical_decomposition_stmt_is_fixed_point() -> None:
    stmt = "∀x₁,x₂∈ℕ:x₁+(x₂+1)≡(x₁+x₂)+1"
    assert normalize(stmt) == stmt


# ── symbol table policy ──────────────────────────────────────────────────────


def test_alias_table_has_no_chains() -> None:
    # Every representative is canonical: it must not itself be an alias key.
    for alias, rep in CANONICAL.items():
        assert rep not in CANONICAL, f"chained alias {alias!r} → {rep!r}"
        assert alias != rep


def test_required_alias_mappings() -> None:
    assert apply_symbol_table("⟶") == "→"
    assert apply_symbol_table("⇾") == "→"
    assert apply_symbol_table("≝") == "≜"
    assert apply_symbol_table("a:=b") == "a≔b"
    assert apply_symbol_table("2*n") == "2·n"
    assert apply_symbol_table("a&&b") == "a∧b"
    assert apply_symbol_table("a||b") == "a∨b"
    assert apply_symbol_table("!a") == "¬a"
    assert apply_symbol_table("a<=b") == "a≤b"
    assert apply_symbol_table("a>=b") == "a≥b"
    assert apply_symbol_table("a!=b") == "a≠b"


def test_exists_unique_is_protected_from_bang_alias() -> None:
    assert apply_symbol_table("∃!n:n≡0") == "∃!n:n≡0"


def test_neq_and_nonequiv_stay_distinct() -> None:
    # ≠ (inequality) and ≢ (non-equivalence) carry different meanings.
    assert normalize("a≠b") != normalize("a≢b")
    assert apply_symbol_table("≢") == "≢"


# ── divergence helper ────────────────────────────────────────────────────────


def test_first_divergence() -> None:
    assert first_divergence("abc", "abc") is None
    assert first_divergence("abc", "abd") == 2
    assert first_divergence("abc", "ab") == 2
    assert first_divergence("", "a") == 0
