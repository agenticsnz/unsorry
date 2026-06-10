"""Redundant-parenthesis elimination (SPEC-003-C step 5) — TDD for the
Phase-0 trial's two false positives (run 001): translations identical up to
a redundant paren wrap of the binder body were flagged.
"""
from __future__ import annotations

import pytest

from tools.fidelity.normalize import normalize, statement_sha


class TestTrialFalsePositives:
    """The exact pairs that flagged in phase0-run-001 must now match."""

    def test_nat_le_refl_pair(self) -> None:
        assert normalize("∀x∈ℕ:x≤x") == normalize("∀n∈ℕ:(n≤n)")

    def test_nat_zero_identity_add_pair(self) -> None:
        assert normalize("∀n∈ℕ:n+0≡n") == normalize("∀n∈ℕ:(n+0≡n)")


class TestStrippedForms:
    def test_whole_statement_wrap(self) -> None:
        assert normalize("(∀n∈ℕ:n+0≡n)") == normalize("∀n∈ℕ:n+0≡n")

    def test_single_token_wrap(self) -> None:
        assert normalize("∀n∈ℕ:(n)+0≡n") == normalize("∀n∈ℕ:n+0≡n")

    def test_directly_nested_duplicate(self) -> None:
        assert normalize("∀n∈ℕ:((n+0≡n))") == normalize("∀n∈ℕ:n+0≡n")

    def test_binder_body_wrap_inside_enclosing_group(self) -> None:
        # the wrapped body ends exactly where the enclosing group closes
        assert normalize("(∀n∈ℕ:(n≤n))∧⊤") == normalize("(∀n∈ℕ:n≤n)∧⊤")

    def test_nested_binders_with_wrapped_inner_body(self) -> None:
        assert normalize("∀a∈ℕ:∃b∈ℕ:(a≤b)") == normalize("∀x∈ℕ:∃y∈ℕ:x≤y")

    def test_lambda_body_wrap(self) -> None:
        assert normalize("λa.(a+1)") == normalize("λn.n+1")


class TestMeaningBearingParensKept:
    def test_binder_body_restriction_not_stripped(self) -> None:
        # (P)∧Q restricts the binder body to P; P∧Q puts ∧Q inside the body
        assert normalize("∀n∈ℕ:(n≤n)∧⊤") != normalize("∀n∈ℕ:n≤n∧⊤")

    def test_interior_grouping_not_stripped(self) -> None:
        # genuinely different statements stay different
        assert normalize("∀a,b,c∈ℕ:(a+b)·c≡a·c+b·c") != normalize(
            "∀a,b,c∈ℕ:a+b·c≡a·c+b·c"
        )

    def test_angle_brackets_never_touched(self) -> None:
        assert "⟨" in normalize("∀p∈ℕ:⟨p⟩≡⟨p⟩")


class TestStability:
    @pytest.mark.parametrize(
        "stmt",
        [
            "∀n∈ℕ:(n+0≡n)",
            "((∀n∈ℕ:n≤n))",
            "∀a∈ℕ:∃b∈ℕ:(a≤b)",
            "∀n∈ℕ:(n≤n)∧⊤",
        ],
    )
    def test_idempotent(self, stmt: str) -> None:
        once = normalize(stmt)
        assert normalize(once) == once

    def test_sha_tracks_normalization(self) -> None:
        assert statement_sha("∀x∈ℕ:x≤x") == statement_sha("∀n∈ℕ:(n≤n)")

    def test_unbalanced_left_untouched(self) -> None:
        # malformed input: conservatively returned without paren surgery
        assert normalize("∀n∈ℕ:(n≤n") == "∀x₁∈ℕ:(x₁≤x₁"
