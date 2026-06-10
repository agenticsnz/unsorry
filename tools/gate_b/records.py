"""Parsing primitives for unsorry AISP coordination records.

Pure, stdlib-only helpers shared by the validator (and by later tools such as
the PR-4 reaper, via :mod:`tools.gate_b.claims`): header-line parsing, block
extraction, field extraction, vectors, UTC timestamps, and the quoted-prose
density lint. No policy lives here — codes and severities belong to
:mod:`tools.gate_b.validator`.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime, timezone

#: Kebab-case identifier grammar shared by goal ids and agent ids (SPEC-003-A).
ID_PATTERN = r"[a-z0-9][a-z0-9-]*"
ID_RE = re.compile(ID_PATTERN)
SHA256_RE = re.compile(r"[0-9a-f]{64}")

#: AISP "no value" glyph.
EMPTY = "∅"

#: Header line: ``𝔸<version>.<type>.<name>@YYYY-MM-DD``.
HEADER_RE = re.compile(
    r"𝔸(?P<version>\d+(?:\.\d+)*?)\.(?P<rtype>[a-z]+)\."
    r"(?P<name>[^@\s]+)@(?P<date>\d{4}-\d{2}-\d{2})"
)
GAMMA_RE = re.compile(r"^γ≔(?P<value>\S+)\s*$", re.MULTILINE)

#: Formal blocks ``⟦Λ:Name⟧{...}`` — inline or multiline; bodies contain no
#: nested braces (the record grammar reserves ``{}`` for block delimiters).
BLOCK_RE = re.compile(
    r"⟦(?P<letter>[^⟧:{\s]+)(?::(?P<name>[^⟧]*))?⟧\{(?P<body>.*?)\}", re.DOTALL
)
EVIDENCE_RE = re.compile(r"⟦Ε⟧⟨[^⟩]*⟩")

QUOTED_RE = re.compile(r'"([^"]*)"')
_WS_RE = re.compile(r"\s+")

_TS_FORMAT = "%Y-%m-%dT%H:%M:%SZ"
_TS_RE = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z")


@dataclass(frozen=True)
class Header:
    version: str
    rtype: str
    name: str
    date: str


@dataclass(frozen=True)
class Block:
    letter: str
    name: str | None
    body: str


@dataclass(frozen=True)
class Record:
    header: Header | None
    gamma: str | None
    blocks: tuple[Block, ...]
    fields: dict[str, str]
    has_evidence: bool

    def block(self, letter: str) -> Block | None:
        for candidate in self.blocks:
            if candidate.letter == letter:
                return candidate
        return None


def is_id(value: str) -> bool:
    return ID_RE.fullmatch(value) is not None


def is_sha256(value: str) -> bool:
    return SHA256_RE.fullmatch(value) is not None


def parse_header(line: str) -> Header | None:
    match = HEADER_RE.fullmatch(line.strip())
    if match is None:
        return None
    return Header(
        version=match.group("version"),
        rtype=match.group("rtype"),
        name=match.group("name"),
        date=match.group("date"),
    )


def parse_fields(body: str) -> dict[str, str]:
    """Extract ``key≜value`` fields from a block body.

    Segments are split on newlines and ``;``. Only the first ``≜`` binds, so
    nested tuples (``sub₁≜⟨id≜…,stmt≜…⟩``) stay intact as values. Segments
    without ``≜`` (e.g. expiry rules, decomposition edges) are ignored.
    """
    fields: dict[str, str] = {}
    for line in body.splitlines():
        for segment in line.split(";"):
            segment = segment.strip()
            if "≜" not in segment:
                continue
            key, value = segment.split("≜", 1)
            key = key.strip()
            if key:
                fields.setdefault(key, value.strip())
    return fields


def parse_record(text: str) -> Record:
    lines = text.splitlines()
    header = parse_header(lines[0]) if lines else None
    gamma_match = GAMMA_RE.search(text)
    blocks = tuple(
        Block(
            letter=match.group("letter"),
            name=(match.group("name") or "").strip() or None,
            body=match.group("body"),
        )
        for match in BLOCK_RE.finditer(text)
    )
    fields: dict[str, str] = {}
    for block in blocks:
        for key, value in parse_fields(block.body).items():
            fields.setdefault(key, value)
    return Record(
        header=header,
        gamma=gamma_match.group("value") if gamma_match else None,
        blocks=blocks,
        fields=fields,
        has_evidence=EVIDENCE_RE.search(text) is not None,
    )


def parse_vector(value: str) -> list[str] | None:
    """Parse ``⟨⟩`` / ``⟨a,b⟩`` into a list; ``None`` if not a vector."""
    value = value.strip()
    if not (value.startswith("⟨") and value.endswith("⟩")):
        return None
    inner = value[1:-1].strip()
    if not inner:
        return []
    return [item.strip() for item in inner.split(",")]


def parse_utc_z(value: str) -> datetime | None:
    """Parse a strict ISO-8601 UTC timestamp with ``Z`` suffix."""
    if _TS_RE.fullmatch(value.strip()) is None:
        return None
    return datetime.strptime(value.strip(), _TS_FORMAT).replace(tzinfo=timezone.utc)


def format_utc_z(moment: datetime) -> str:
    return moment.astimezone(timezone.utc).strftime(_TS_FORMAT)


def prose_density(record: Record) -> float:
    """GB009 metric: quoted chars ÷ non-whitespace chars in formal blocks.

    Both counts ignore whitespace so the ratio is a true proportion in
    ``[0, 1]`` regardless of how the quoted prose is spaced.
    """
    bodies = "\n".join(block.body for block in record.blocks)
    total = len(_WS_RE.sub("", bodies))
    if total == 0:
        return 0.0
    quoted = "".join(QUOTED_RE.findall(bodies))
    return len(_WS_RE.sub("", quoted)) / total
