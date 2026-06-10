"""Unit tests for the AISP record-parsing primitives and claim expiry logic."""
from __future__ import annotations

from datetime import timedelta
from pathlib import Path

from tools.gate_b import claims
from tools.gate_b.records import (
    parse_header,
    parse_record,
    parse_utc_z,
    parse_vector,
    prose_density,
)

FIXTURES = Path(__file__).resolve().parent / "fixtures"

GOAL_TEXT = (FIXTURES / "valid_tree" / "goals" / "nat-succ-pos.aisp").read_text("utf-8")
CLAIM_PATH = FIXTURES / "claims_valid" / "claims" / "nat-add-comm.agent-alpha.aisp"


# -------------------------------------------------------------------- headers


def test_parse_header_goal():
    header = parse_header("𝔸5.1.goal.nat-succ-pos@2026-06-10")
    assert header is not None
    assert header.version == "5.1"
    assert header.rtype == "goal"
    assert header.name == "nat-succ-pos"
    assert header.date == "2026-06-10"


def test_parse_header_claim_keeps_dotted_name():
    header = parse_header("𝔸5.1.claim.nat-add-comm.agent-alpha@2026-06-10")
    assert header is not None
    assert header.rtype == "claim"
    assert header.name == "nat-add-comm.agent-alpha"


def test_parse_header_rejects_garbage():
    assert parse_header("not a header") is None
    assert parse_header("𝔸5.1.goal.missing-date") is None


# --------------------------------------------------------------------- blocks


def test_parse_record_extracts_blocks_fields_and_evidence():
    record = parse_record(GOAL_TEXT)
    assert record.gamma == "unsorry.goal"
    assert [b.letter for b in record.blocks] == ["Ω", "Σ", "Γ", "Λ"]
    assert record.has_evidence
    assert record.fields["id"] == "nat-succ-pos"
    assert record.fields["phase"] == "prove"
    assert record.fields["status"] == "proved"
    assert record.fields["src"] == "backlog/nat-succ-pos.md"


def test_parse_record_handles_inline_blocks():
    text = CLAIM_PATH.read_text("utf-8")
    record = parse_record(text)
    assert record.fields["goal"] == "nat-add-comm"
    assert record.fields["agent"] == "agent-alpha"
    assert record.fields["ts"] == "2026-06-10T00:00:00Z"
    assert record.fields["ttl"] == "7200"


def test_parse_vector():
    assert parse_vector("⟨⟩") == []
    assert parse_vector("⟨a⟩") == ["a"]
    assert parse_vector("⟨a, b⟩") == ["a", "b"]
    assert parse_vector("not-a-vector") is None


# ----------------------------------------------------------------- timestamps


def test_parse_utc_z():
    ts = parse_utc_z("2026-06-10T00:00:00Z")
    assert ts is not None and ts.tzinfo is not None
    assert parse_utc_z("2026-06-10T00:00:00") is None
    assert parse_utc_z("2026-06-10") is None
    assert parse_utc_z("garbage") is None


# -------------------------------------------------------------- prose density


def test_prose_density_zero_for_symbolic_record():
    assert prose_density(parse_record(GOAL_TEXT)) == 0.0


def test_prose_density_counts_quoted_chars():
    prosey = FIXTURES / "invalid_prose_density" / "goals" / "prosey.aisp"
    record = parse_record(prosey.read_text("utf-8"))
    assert prose_density(record) > 0.30


# --------------------------------------------------------------------- claims


def test_parse_claim_from_fixture():
    claim = claims.parse_claim(CLAIM_PATH)
    assert claim.filename_goal == "nat-add-comm"
    assert claim.filename_agent == "agent-alpha"
    assert claim.goal == "nat-add-comm"
    assert claim.agent == "agent-alpha"
    assert claim.ttl == 7200
    assert claim.ts == parse_utc_z("2026-06-10T00:00:00Z")


def test_split_claim_filename_requires_exactly_two_dots():
    assert claims.split_claim_filename("goal-x.agent-y.aisp") == ("goal-x", "agent-y")
    assert claims.split_claim_filename("onlyonefield.aisp") is None
    assert claims.split_claim_filename("a.b.c.aisp") is None
    assert claims.split_claim_filename("goal-x.agent-y.txt") is None
    assert claims.split_claim_filename("Goal.agent.aisp") is None  # Id grammar


def test_claim_liveness_boundary_now_equal_expiry_is_live():
    claim = claims.parse_claim(CLAIM_PATH)
    expiry = claims.expires_at(claim)
    assert expiry == claim.ts + timedelta(seconds=7200)
    assert claims.is_live(claim, expiry)
    assert not claims.is_expired(claim, expiry)
    one_second_later = expiry + timedelta(seconds=1)
    assert claims.is_expired(claim, one_second_later)
    assert not claims.is_live(claim, one_second_later)


def test_unparsable_claim_is_neither_live_nor_expired():
    broken = claims.parse_claim_text("x.y.aisp", "not an aisp record")
    assert claims.expires_at(broken) is None
    assert not claims.is_live(broken, parse_utc_z("2026-06-10T00:00:00Z"))
    assert not claims.is_expired(broken, parse_utc_z("2026-06-10T00:00:00Z"))
