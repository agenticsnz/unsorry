"""Generate the ADR index (ADR-073 / SPEC-073-A).

A one-glance view of every Architecture Decision Record in ``docs/adrs/`` — its
number, title, status, and date — rendered both for humans (``docs/adrs/README.md``,
a Markdown table) and for machines (``docs/adrs/adrs.json``). The data source is the
``ADR-*.md`` files themselves: each carries a uniform header table with ``**Status**``
and ``**Date**`` rows and an ``# ADR-NNN: Title`` H1, so the index is mechanically
derivable and never hand-maintained.

The output is **deterministic** — no wall-clock timestamp is embedded — so the
``--check`` drift gate can compare freshly rendered content byte-for-byte against the
committed files, exactly like the leaderboard / targets / queue generators.

Usage::

    python3 -m tools.adr_index [<repo-root>]            # README Markdown to stdout
    python3 -m tools.adr_index --json [<repo-root>]     # adrs.json to stdout
    python3 -m tools.adr_index --write [<repo-root>]    # write docs/adrs/README.md + adrs.json
    python3 -m tools.adr_index --check [<repo-root>]    # CI drift check (exit 1 if stale)
"""
from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

#: Output filenames, both written under ``docs/adrs/``.
README_NAME = "README.md"
JSON_NAME = "adrs.json"

#: How the generated artifacts say they were produced (banner + JSON provenance).
GENERATED_BY = "python3 -m tools.adr_index --write"

_NUMBER_RE = re.compile(r"^ADR-(\d+)", re.IGNORECASE)
_FILENAME_PREFIX_RE = re.compile(r"^ADR-\d+[A-Za-z]?-", re.IGNORECASE)
_H1_RE = re.compile(r"^#\s+(.+?)\s*$", re.MULTILINE)
_H1_ADR_PREFIX_RE = re.compile(r"^ADR-\d+[A-Za-z]?\s*[:\-–—]\s*(.*)$")


@dataclass(frozen=True)
class Adr:
    """One ADR's index row, parsed from its ``ADR-*.md`` file."""

    id: str  # zero-padded canonical id, e.g. "ADR-041"
    number: int
    title: str
    status: str
    date: str
    file: str  # filename within docs/adrs/, e.g. "ADR-001-Adopt-Development-Protocols.md"


# ── Pure parsers ──────────────────────────────────────────────────────────────


def parse_number(filename: str) -> int | None:
    """The leading ``ADR-<n>`` number from a filename, or ``None`` if not an ADR file."""
    match = _NUMBER_RE.match(filename)
    return int(match.group(1)) if match else None


def title_from_filename(filename: str) -> str:
    """Fallback title: strip the ``ADR-NNN-`` prefix and ``.md``, hyphens → spaces."""
    stem = filename[:-3] if filename.endswith(".md") else filename
    stem = _FILENAME_PREFIX_RE.sub("", stem)
    return stem.replace("-", " ").strip()


def parse_title(text: str, fallback: str) -> str:
    """Title from the first H1, with any leading ``ADR-NNN:`` prefix removed.

    Falls back to ``fallback`` (typically :func:`title_from_filename`) when the file
    has no H1.
    """
    match = _H1_RE.search(text)
    if not match:
        return fallback
    heading = match.group(1).strip()
    prefixed = _H1_ADR_PREFIX_RE.match(heading)
    title = (prefixed.group(1).strip() if prefixed else heading)
    return title or fallback


def parse_field(text: str, field: str) -> str | None:
    """Value of a ``| **<field>** | <value> |`` header-table row, or ``None``.

    The full cell is kept verbatim (e.g. an ``Accepted (sponsor signed up: …)``
    status), trimmed of surrounding whitespace.
    """
    pattern = re.compile(
        r"^\|\s*\*\*" + re.escape(field) + r"\*\*\s*\|\s*(.+?)\s*\|",
        re.MULTILINE,
    )
    match = pattern.search(text)
    return match.group(1).strip() if match else None


# ── Collection ────────────────────────────────────────────────────────────────


def collect_adrs(root: Path) -> list[Adr]:
    """All ``docs/adrs/ADR-*.md`` files as :class:`Adr` rows, sorted by ``(number, file)``.

    The non-recursive glob naturally excludes ``README.md``, ``adrs.json``, and the
    ``specs/`` subdirectory. Duplicate ADR numbers (the corpus has two ``ADR-041``s)
    are all listed; a non-fatal ``::warning::`` is printed to stderr so CI surfaces it.
    """
    adr_dir = root / "docs" / "adrs"
    adrs: list[Adr] = []
    for path in sorted(adr_dir.glob("ADR-*.md")):
        number = parse_number(path.name)
        if number is None:
            continue
        text = path.read_text(encoding="utf-8")
        adrs.append(
            Adr(
                id=f"ADR-{number:03d}",
                number=number,
                title=parse_title(text, title_from_filename(path.name)),
                status=parse_field(text, "Status") or "Unknown",
                date=parse_field(text, "Date") or "—",
                file=path.name,
            )
        )
    adrs.sort(key=lambda a: (a.number, a.file))

    by_number: dict[int, list[str]] = {}
    for adr in adrs:
        by_number.setdefault(adr.number, []).append(adr.file)
    for number, files in sorted(by_number.items()):
        if len(files) > 1:
            print(
                f"::warning::duplicate ADR number {number:03d}: {', '.join(files)}",
                file=sys.stderr,
            )
    return adrs


# ── Rendering ─────────────────────────────────────────────────────────────────


def _cell(value: str) -> str:
    """Escape Markdown table-cell delimiters so a stray ``|`` can't break the table."""
    return value.replace("|", "\\|")


def render_markdown(adrs: list[Adr]) -> str:
    """The human-facing ``README.md`` table."""
    lines = [
        f"<!-- GENERATED by `{GENERATED_BY}`. Do not edit by hand. -->",
        "",
        "# Architecture Decision Records",
        "",
        f"Index of the {len(adrs)} ADRs in this directory, generated from the "
        "`ADR-*.md` headers and kept in sync by the `adr-index` workflow. See "
        "[ADR-001](ADR-001-Adopt-Development-Protocols.md) and "
        "[the development protocols](../protocols.md) for the WH(Y) format and process.",
        "",
        "| ADR | Title | Status | Date |",
        "|-----|-------|--------|------|",
    ]
    lines.extend(
        f"| [{adr.id}]({adr.file}) | {_cell(adr.title)} | {_cell(adr.status)} | {_cell(adr.date)} |"
        for adr in adrs
    )
    return "\n".join(lines) + "\n"


def render_json(adrs: list[Adr]) -> str:
    """The machine-facing ``adrs.json`` index."""
    payload = {
        "generated_by": GENERATED_BY,
        "count": len(adrs),
        "adrs": [
            {
                "id": adr.id,
                "number": adr.number,
                "title": adr.title,
                "status": adr.status,
                "date": adr.date,
                "file": adr.file,
            }
            for adr in adrs
        ],
    }
    return json.dumps(payload, indent=2, ensure_ascii=False) + "\n"


# ── CLI ───────────────────────────────────────────────────────────────────────


def _artifacts(root: Path, adrs: list[Adr]) -> list[tuple[Path, str]]:
    adr_dir = root / "docs" / "adrs"
    return [
        (adr_dir / README_NAME, render_markdown(adrs)),
        (adr_dir / JSON_NAME, render_json(adrs)),
    ]


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    flags = ("--check", "--write", "--json")
    modes = [flag for flag in flags if flag in argv]
    if len(modes) > 1:
        print(f"{', '.join(flags)} are mutually exclusive", file=sys.stderr)
        return 2
    mode = modes[0] if modes else None

    rest = [arg for arg in argv if arg not in flags]
    root = Path(rest[0]) if rest else Path(".")
    adrs = collect_adrs(root)

    if mode == "--json":
        sys.stdout.write(render_json(adrs))
        return 0

    artifacts = _artifacts(root, adrs)
    if mode == "--write":
        for target, content in artifacts:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
        return 0
    if mode == "--check":
        stale = [
            str(target)
            for target, content in artifacts
            if (target.read_text(encoding="utf-8") if target.exists() else "") != content
        ]
        if stale:
            print(
                f"{', '.join(stale)} stale; regenerate with `{GENERATED_BY}`",
                file=sys.stderr,
            )
            return 1
        return 0

    sys.stdout.write(render_markdown(adrs))
    return 0
