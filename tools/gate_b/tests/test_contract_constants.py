"""SPEC-003-D acceptance: tools/gate_b/config.py mirrors swarm/protocol.aisp.

The contract is the normative source; config.py is the mirror. A light regex
parse of the protocol must agree with every constant config.py exports.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.gate_b import config

PROTOCOL = (Path(__file__).resolve().parents[3] / "swarm" / "protocol.aisp").read_text(
    "utf-8"
)


def extract(pattern: str) -> int:
    match = re.search(pattern, PROTOCOL)
    assert match, f"protocol.aisp no longer contains /{pattern}/"
    return int(match.group(1))


def test_ttl_default():
    assert extract(r"ttl≜(\d+)") == config.TTL_SECONDS == 7200


def test_ttl_bounds():
    match = re.search(r"(\d+)≤ttl≤(\d+)", PROTOCOL)
    assert match, "protocol.aisp no longer states ttl bounds"
    assert int(match.group(1)) == config.TTL_MIN_SECONDS == 600
    assert int(match.group(2)) == config.TTL_MAX_SECONDS == 86400


def test_reaper_interval():
    assert extract(r"cron\(≤(\d+)s\)") == config.REAPER_INTERVAL_SECONDS == 900


def test_ttl_covers_four_reaper_intervals():
    assert re.search(r"ttl≥4×cron", PROTOCOL)
    assert config.TTL_SECONDS >= 4 * config.REAPER_INTERVAL_SECONDS


def test_translate_claim_cap():
    assert (
        extract(r"phase≡translate⇒\|live\(goal\)\|≤(\d+)")
        == config.TRANSLATE_CLAIM_CAP
        == 2
    )


def test_prove_claim_cap():
    assert extract(r"phase≡prove⇒\|live\(goal\)\|≤(\d+)") == config.PROVE_CLAIM_CAP == 1


def test_budgets():
    assert extract(r"turns≤(\d+)") == config.BUDGET_TURNS == 40
    assert extract(r"wall≤(\d+)s") == config.BUDGET_WALL_SECONDS == 1800
    assert extract(r"attempts≤(\d+)") == config.BUDGET_ATTEMPTS == 2


def test_tau_v_viability_threshold():
    # protocol.aisp writes the minus as U+2212: τ_v≜−5
    assert -extract(r"τ_v≜[−-](\d+)") == config.TAU_V == -5


def test_prose_density_ceiling():
    # Not a protocol constant — normative source is SPEC-003-A GB009.
    assert config.PROSE_DENSITY_CEILING == 0.30
