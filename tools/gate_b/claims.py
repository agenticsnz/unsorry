"""Claim parsing and expiry logic (SPEC-003-B).

Kept separate from the validator on purpose: the PR-4 reaper imports this
module to decide which claim files on the ``claims`` branch are expired. All
clock-dependent functions take ``now`` explicitly — nothing here ever reads
the wall clock.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path

from .records import Record, is_id, parse_record, parse_utc_z

CLAIM_SUFFIX = ".aisp"


@dataclass(frozen=True)
class Claim:
    """One parsed ``claims/<goal-id>.<agent-id>.aisp`` record.

    Fields that fail to parse are ``None``; policy (which Gate B code that
    is) belongs to the validator, and the reaper treats unparsable claims as
    neither live nor expired.
    """

    filename: str
    filename_goal: str | None
    filename_agent: str | None
    goal: str | None
    agent: str | None
    ts: datetime | None
    ttl: int | None
    record: Record


def split_claim_filename(filename: str) -> tuple[str, str] | None:
    """Split ``<goal-id>.<agent-id>.aisp`` — exactly two dots, both ids."""
    if not filename.endswith(CLAIM_SUFFIX):
        return None
    parts = filename[: -len(CLAIM_SUFFIX)].split(".")
    if len(parts) != 2 or not all(is_id(part) for part in parts):
        return None
    return parts[0], parts[1]


def parse_claim_text(filename: str, text: str) -> Claim:
    record = parse_record(text)
    fields = record.fields
    name_fields = split_claim_filename(filename)
    ttl_raw = fields.get("ttl", "")
    return Claim(
        filename=filename,
        filename_goal=name_fields[0] if name_fields else None,
        filename_agent=name_fields[1] if name_fields else None,
        goal=fields.get("goal"),
        agent=fields.get("agent"),
        ts=parse_utc_z(fields.get("ts", "")),
        ttl=int(ttl_raw) if ttl_raw.isdigit() else None,
        record=record,
    )


def parse_claim(path: Path) -> Claim:
    return parse_claim_text(path.name, path.read_text(encoding="utf-8"))


def expires_at(claim: Claim) -> datetime | None:
    if claim.ts is None or claim.ttl is None:
        return None
    return claim.ts + timedelta(seconds=claim.ttl)


def is_expired(claim: Claim, now: datetime) -> bool:
    """``now > ts + ttl ⇒ expired`` (protocol ⟦Γ:Claims⟧). False if unparsable."""
    expiry = expires_at(claim)
    return expiry is not None and now > expiry


def is_live(claim: Claim, now: datetime) -> bool:
    """Live iff the expiry is known and ``now ≤ ts + ttl``."""
    expiry = expires_at(claim)
    return expiry is not None and now <= expiry
