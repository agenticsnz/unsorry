"""Unit tests for the domain-admission registry + predicates (SPEC-080-A)."""
from __future__ import annotations

from pathlib import Path

import pytest

from tools.governance.admission import (
    Registry,
    RegistryError,
    domain_admissible,
    load_registry,
    parse_registry,
    target_curated,
)

REPO_ROOT = Path(__file__).resolve().parents[3]
SHIPPED_REGISTRY = REPO_ROOT / "docs" / "governance" / "admitted-domains.json"


def _registry(domains=(), targets=()) -> Registry:
    return parse_registry(
        {"schema_version": 1, "domains": list(domains), "targets": list(targets)}
    )


# ----------------------------------------------------------- domain_admissible


def test_verified_domain_is_admissible():
    reg = _registry(
        domains=[{"id": "lean-math", "verifier": "lean-kernel", "tier": "VERIFIED"}]
    )
    assert domain_admissible("lean-math", reg) is True


def test_scored_domain_is_not_admissible():
    # ranks 4-9 (soft oracle) carry a non-VERIFIED tier → rejected (ADR-080 clause 3)
    reg = _registry(domains=[{"id": "fusion", "verifier": "sim", "tier": "SCORED"}])
    assert domain_admissible("fusion", reg) is False


def test_absent_domain_is_not_admissible():
    reg = _registry(
        domains=[{"id": "lean-math", "verifier": "lean-kernel", "tier": "VERIFIED"}]
    )
    assert domain_admissible("astrology", reg) is False


# ------------------------------------------------------------- target_curated


def test_registered_target_returns_supplier():
    reg = _registry(
        targets=[
            {"package": "putnambench", "domain": "lean-math", "supplier": "trishul"}
        ]
    )
    supplier = target_curated("putnambench", reg)
    assert supplier is not None
    assert supplier.supplier == "trishul"
    assert supplier.domain == "lean-math"


def test_self_minted_package_is_not_curated():
    reg = _registry(
        targets=[
            {"package": "putnambench", "domain": "lean-math", "supplier": "trishul"}
        ]
    )
    assert target_curated("my-own-thing", reg) is None


# --------------------------------------------------------- registry validation


def test_bad_schema_version_rejected():
    with pytest.raises(RegistryError):
        parse_registry({"schema_version": 2, "domains": [], "targets": []})


def test_malformed_domain_entry_rejected():
    with pytest.raises(RegistryError):  # missing verifier/tier
        parse_registry(
            {"schema_version": 1, "domains": [{"id": "x"}], "targets": []}
        )


def test_non_object_root_rejected():
    with pytest.raises(RegistryError):
        parse_registry([1, 2, 3])


def test_targets_must_be_a_list():
    with pytest.raises(RegistryError):
        parse_registry({"schema_version": 1, "domains": [], "targets": {}})


def test_missing_file_rejected():
    with pytest.raises(RegistryError):
        load_registry(REPO_ROOT / "docs" / "governance" / "does-not-exist.json")


# ------------------------------------------------------ the shipped registry


def test_shipped_registry_loads_and_admits_lean_math():
    reg = load_registry(SHIPPED_REGISTRY)
    assert isinstance(reg, Registry)
    assert domain_admissible("lean-math", reg) is True
    # nothing below VERIFIED sneaks in
    assert all(d.tier == "VERIFIED" for d in reg.domains)
