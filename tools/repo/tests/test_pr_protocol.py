"""Tests for the protocol-compliance gate (ADR-028, ADR-061)."""
from __future__ import annotations

from tools.repo.pr_protocol import check


def test_adr_with_spec_in_same_pr_passes():
    added = [
        "docs/adrs/ADR-099-Thing.md",
        "docs/adrs/specs/SPEC-099-A-Thing.md",
    ]
    assert check(added, []) == []


def test_adr_without_any_spec_is_flagged():
    added = ["docs/adrs/ADR-099-Thing.md"]
    out = check(added, [])
    assert len(out) == 1 and "ADR-099" in out[0] and "SPEC-099" in out[0]


def test_adr_paired_with_preexisting_spec_passes():
    # spec already on the base tree (e.g. an ADR reusing/extending an existing spec)
    added = ["docs/adrs/ADR-099-Thing.md"]
    existing = ["docs/adrs/specs/SPEC-099-A-Thing.md"]
    assert check(added, existing) == []


def test_orphan_spec_is_flagged():
    added = ["docs/adrs/specs/SPEC-099-A-Thing.md"]
    out = check(added, [])
    assert len(out) == 1 and "SPEC-099" in out[0] and "ADR-099" in out[0]


def test_historical_unpaired_adrs_are_not_flagged():
    # Only ADDED paths are checked; a pre-existing unpaired ADR (e.g. ADR-001)
    # in `existing` must not produce a violation.
    added = ["docs/adrs/ADR-100-New.md", "docs/adrs/specs/SPEC-100-A-New.md"]
    existing = ["docs/adrs/ADR-001-Protocols.md"]  # no SPEC-001 anywhere
    assert check(added, existing) == []


def test_non_adr_changes_are_ignored():
    assert check(["swarm/agent.sh", "CHANGELOG.md", "README.md"], []) == []


# --- number uniqueness (ADR-061) --------------------------------------------


def test_adr_number_colliding_with_base_tree_is_flagged():
    # The #983/#1837 incident: a PR adds ADR-059-Bar while base already has a
    # different ADR-059. (Spec added too, so only the uniqueness rule fires.)
    added = ["docs/adrs/ADR-059-Bar.md", "docs/adrs/specs/SPEC-059-A-Bar.md"]
    existing = [
        "docs/adrs/ADR-059-Foo.md",
        "docs/adrs/specs/SPEC-059-A-Foo.md",
    ]
    out = check(added, existing)
    assert any("ADR-059 number is reused" in v for v in out)
    assert any("ADR-059-Foo.md" in v and "ADR-059-Bar.md" in v for v in out)


def test_two_added_adrs_sharing_a_number_are_flagged():
    added = [
        "docs/adrs/ADR-099-One.md",
        "docs/adrs/ADR-099-Two.md",
        "docs/adrs/specs/SPEC-099-A-One.md",
    ]
    out = check(added, [])
    assert any("ADR-099 number is reused" in v for v in out)


def test_fresh_unique_adr_number_passes():
    added = ["docs/adrs/ADR-200-New.md", "docs/adrs/specs/SPEC-200-A-New.md"]
    existing = ["docs/adrs/ADR-059-Foo.md", "docs/adrs/specs/SPEC-059-A-Foo.md"]
    assert check(added, existing) == []


def test_new_spec_letter_for_existing_adr_number_is_allowed():
    # SPEC-003-B added when SPEC-003-A already exists is legitimate (one ADR,
    # multiple spec parts) — must NOT be flagged as a number collision.
    added = ["docs/adrs/specs/SPEC-003-B-Second-Part.md"]
    existing = [
        "docs/adrs/ADR-003-Thing.md",
        "docs/adrs/specs/SPEC-003-A-First-Part.md",
    ]
    assert check(added, existing) == []


def test_duplicate_spec_letter_is_flagged():
    added = ["docs/adrs/specs/SPEC-003-A-Dup.md"]
    existing = [
        "docs/adrs/ADR-003-Thing.md",
        "docs/adrs/specs/SPEC-003-A-Original.md",
    ]
    out = check(added, existing)
    assert any("SPEC-003-A number is reused" in v for v in out)


def test_preexisting_duplicate_does_not_block_unrelated_pr():
    # A pre-existing ADR-059 duplicate on the base tree must not fail a PR that
    # touches neither — only added files trigger violations.
    added = ["docs/adrs/ADR-200-New.md", "docs/adrs/specs/SPEC-200-A-New.md"]
    existing = ["docs/adrs/ADR-059-Foo.md", "docs/adrs/ADR-059-Bar.md"]
    assert check(added, existing) == []
