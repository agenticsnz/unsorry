"""Tests for extracting `stmt≜…` from AISP translation records.

Acceptance criterion 3 (SPEC-003-C): the sha of the worked example in
valid_tree matches the value committed in its goal record and index entry.
"""

from __future__ import annotations

import re

import pytest

from conftest import VALID_TREE
from tools.fidelity.extract import ExtractError, extract_stmt, statement_from_source
from tools.fidelity.normalize import normalize, statement_sha

TRANSLATION_ALPHA = VALID_TREE / "translations" / "nat-zero-add.agent-alpha.aisp"
TRANSLATION_BETA = VALID_TREE / "translations" / "nat-zero-add.agent-beta.aisp"
GOAL_RECORD = VALID_TREE / "goals" / "nat-zero-add.aisp"

# Pinned expected value (also asserted against the fixture text below).
EXPECTED_SHA = "73026be938ddd22261b6c55a2a5843465916f04559e06406d91b71b414b797a8"


def _goal_record_sha() -> str:
    text = GOAL_RECORD.read_text(encoding="utf-8")
    match = re.search(r"sha≜([0-9a-f]{64})", text)
    assert match, "goal fixture should carry a 64-hex sha"
    return match.group(1)


def test_extracts_stmt_from_both_translation_records() -> None:
    alpha = extract_stmt(TRANSLATION_ALPHA.read_text(encoding="utf-8"))
    beta = extract_stmt(TRANSLATION_BETA.read_text(encoding="utf-8"))
    assert alpha == "∀n∈ℕ:0+n≡n"
    assert beta == "∀m∈ℕ:0+m≡m"


def test_translation_records_match_after_normalization() -> None:
    alpha = extract_stmt(TRANSLATION_ALPHA.read_text(encoding="utf-8"))
    beta = extract_stmt(TRANSLATION_BETA.read_text(encoding="utf-8"))
    assert normalize(alpha) == normalize(beta)


def test_sha_matches_goal_record_fixture() -> None:
    recorded = _goal_record_sha()
    assert recorded == EXPECTED_SHA
    alpha = extract_stmt(TRANSLATION_ALPHA.read_text(encoding="utf-8"))
    beta = extract_stmt(TRANSLATION_BETA.read_text(encoding="utf-8"))
    assert statement_sha(alpha) == recorded
    assert statement_sha(beta) == recorded


def test_extract_inline_block_form() -> None:
    assert (
        statement_from_source("⟦Σ:Stmt⟧{stmt≜∀n∈ℕ:0+n≡n}") == "∀n∈ℕ:0+n≡n"
    )


def test_extract_error_when_no_stmt_block() -> None:
    # A goal record has ⟦Σ:Source⟧ but no ⟦Σ:Stmt⟧ block.
    with pytest.raises(ExtractError):
        extract_stmt(GOAL_RECORD.read_text(encoding="utf-8"))


def test_statement_from_source_passes_raw_statements_through() -> None:
    assert statement_from_source("∀n∈ℕ:0+n≡n\n") == "∀n∈ℕ:0+n≡n"
