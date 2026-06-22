"""ADR-index generator tests (ADR-073 / SPEC-073-A).

Pure unit tests over constructed ADR text plus a hermetic ``--write`` / ``--check``
round-trip against a temporary ``docs/adrs`` tree. No network, no real repo.
"""
from __future__ import annotations

import json
from pathlib import Path

from tools.adr_index.generate import (
    Adr,
    collect_adrs,
    main,
    parse_field,
    parse_number,
    parse_title,
    render_json,
    render_markdown,
    title_from_filename,
)


# ── helpers ──────────────────────────────────────────────────────────────────


def _adr_text(number: str, title: str, *, status="Accepted", date="2026-06-10", h1=True):
    """A minimal ADR file body matching the repo's header-table shape."""
    head = f"# ADR-{number}: {title}\n\n" if h1 else ""
    return (
        head
        + "| Field | Value |\n"
        + "|-------|-------|\n"
        + f"| **Decision ID** | ADR-{number} |\n"
        + f"| **Date** | {date} |\n"
        + f"| **Status** | {status} |\n"
    )


def _make_adr_dir(root: Path, files: dict[str, str]) -> Path:
    adr_dir = root / "docs" / "adrs"
    adr_dir.mkdir(parents=True, exist_ok=True)
    for name, body in files.items():
        (adr_dir / name).write_text(body, encoding="utf-8")
    return adr_dir


# ── pure parsers ─────────────────────────────────────────────────────────────


def test_parse_number():
    assert parse_number("ADR-001-Adopt-Development-Protocols.md") == 1
    assert parse_number("ADR-073-ADR-Index-Generated-README.md") == 73
    # Not an ADR file → None (README.md / adrs.json are excluded this way).
    assert parse_number("README.md") is None
    assert parse_number("adrs.json") is None


def test_parse_title_from_h1_strips_adr_prefix():
    text = _adr_text("001", "Adopt Development Protocols")
    assert parse_title(text, "fallback") == "Adopt Development Protocols"
    # A title with backticks/dashes survives verbatim.
    text2 = _adr_text("041", "OpenAI `--prove` Text-Extraction Fallback")
    assert parse_title(text2, "fallback") == "OpenAI `--prove` Text-Extraction Fallback"


def test_parse_title_falls_back_when_no_h1():
    text = _adr_text("008", "ignored", h1=False)
    assert parse_title(text, "Derived Title") == "Derived Title"


def test_title_from_filename():
    assert (
        title_from_filename("ADR-002-Lean4-Mathlib-Pinned-Release-Tags.md")
        == "Lean4 Mathlib Pinned Release Tags"
    )


def test_parse_field_status_and_date():
    text = _adr_text("005", "x", status="Proposed", date="2026-06-16")
    assert parse_field(text, "Status") == "Proposed"
    assert parse_field(text, "Date") == "2026-06-16"


def test_parse_field_keeps_parenthetical_status_verbatim():
    text = _adr_text("020", "x", status="Accepted (sponsor signed up: Chris Barlow, 2026-06-12)")
    assert parse_field(text, "Status") == "Accepted (sponsor signed up: Chris Barlow, 2026-06-12)"


def test_parse_field_missing_returns_none():
    assert parse_field("# ADR-099: no table here\n", "Status") is None


# ── collection ───────────────────────────────────────────────────────────────


def test_collect_sorts_by_number_then_file(tmp_path):
    _make_adr_dir(
        tmp_path,
        {
            "ADR-010-Bravo.md": _adr_text("010", "Bravo"),
            "ADR-002-Alpha.md": _adr_text("002", "Alpha", status="Proposed"),
            "README.md": "not an adr",
        },
    )
    adrs = collect_adrs(tmp_path)
    assert [a.number for a in adrs] == [2, 10]
    assert adrs[0].id == "ADR-002" and adrs[0].status == "Proposed"
    # README.md is not picked up as an ADR.
    assert all(a.file != "README.md" for a in adrs)


def test_collect_keeps_both_duplicate_numbers(tmp_path, capsys):
    _make_adr_dir(
        tmp_path,
        {
            "ADR-041-Alpha.md": _adr_text("041", "Alpha"),
            "ADR-041-Beta.md": _adr_text("041", "Beta"),
        },
    )
    adrs = collect_adrs(tmp_path)
    # Both rows present, sorted by (number, filename).
    assert [a.file for a in adrs] == ["ADR-041-Alpha.md", "ADR-041-Beta.md"]
    assert all(a.id == "ADR-041" for a in adrs)
    # A non-fatal warning is emitted to stderr.
    assert "duplicate ADR number 041" in capsys.readouterr().err


# ── rendering ────────────────────────────────────────────────────────────────


def _sample_adrs():
    return [
        Adr("ADR-001", 1, "Adopt Development Protocols", "Accepted", "2026-06-10", "ADR-001-Adopt-Development-Protocols.md"),
        Adr("ADR-060", 60, "Contributor-Facing Goal-Sourcing Skill", "Proposed", "2026-06-17", "ADR-060-Contributor-Goal-Sourcing-Skill.md"),
    ]


def test_render_markdown_has_table_and_links():
    md = render_markdown(_sample_adrs())
    assert "| ADR | Title | Status | Date |" in md
    assert "[ADR-001](ADR-001-Adopt-Development-Protocols.md)" in md
    assert "| Proposed |" in md
    assert md.endswith("\n")
    # Generated-by banner so humans don't hand-edit it.
    assert md.splitlines()[0].startswith("<!-- GENERATED")


def test_render_markdown_escapes_pipes():
    adrs = [Adr("ADR-099", 99, "a | b", "Accepted", "2026-06-10", "ADR-099-x.md")]
    assert r"a \| b" in render_markdown(adrs)


def test_render_json_shape_and_roundtrip():
    payload = json.loads(render_json(_sample_adrs()))
    assert payload["count"] == 2
    assert payload["adrs"][0] == {
        "id": "ADR-001",
        "number": 1,
        "title": "Adopt Development Protocols",
        "status": "Accepted",
        "date": "2026-06-10",
        "file": "ADR-001-Adopt-Development-Protocols.md",
    }
    assert render_json(_sample_adrs()).endswith("\n")


# ── CLI: write / check round-trip ────────────────────────────────────────────


def test_write_then_check_is_in_sync(tmp_path):
    _make_adr_dir(
        tmp_path,
        {
            "ADR-001-Adopt-Development-Protocols.md": _adr_text("001", "Adopt Development Protocols"),
            "ADR-002-Alpha.md": _adr_text("002", "Alpha"),
        },
    )
    assert main(["--write", str(tmp_path)]) == 0
    adr_dir = tmp_path / "docs" / "adrs"
    assert (adr_dir / "README.md").exists()
    assert (adr_dir / "adrs.json").exists()
    # Freshly written → check is clean.
    assert main(["--check", str(tmp_path)]) == 0


def test_check_detects_drift(tmp_path, capsys):
    _make_adr_dir(tmp_path, {"ADR-001-X.md": _adr_text("001", "X")})
    assert main(["--write", str(tmp_path)]) == 0
    # Mutate a status → the index is now stale.
    adr = tmp_path / "docs" / "adrs" / "ADR-001-X.md"
    adr.write_text(_adr_text("001", "X", status="Proposed"), encoding="utf-8")
    assert main(["--check", str(tmp_path)]) == 1
    assert "stale" in capsys.readouterr().err


def test_check_reports_missing_artifacts_as_stale(tmp_path):
    _make_adr_dir(tmp_path, {"ADR-001-X.md": _adr_text("001", "X")})
    # Never written → both artifacts missing → stale.
    assert main(["--check", str(tmp_path)]) == 1


def test_mutually_exclusive_modes(tmp_path):
    _make_adr_dir(tmp_path, {"ADR-001-X.md": _adr_text("001", "X")})
    assert main(["--write", "--check", str(tmp_path)]) == 2
