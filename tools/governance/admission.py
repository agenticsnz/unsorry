"""Domain-admission registry and the gating predicates (SPEC-080-A).

ADR-080's gating invariant — a domain joins the trustless commons only if it carries
a cheap, deterministic, **kernel-grade** verifier — made machine-checkable. A single
auditable registry (``docs/governance/admitted-domains.json``) records the
founder-ratified domains and curated targets; two pure predicates let the intake path
(``skeleton-validate``, SPEC-081-A checks 2/6) and the credit pass (SPEC-078-A's
"curated-only" rule) consult it. No code path admits a domain/target that is not in
the registry. Stdlib-only; the registry is plain JSON.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

#: The only kernel-grade tier that joins the trustless commons (ADR-080 clause 1);
#: softer ADR-052 tiers (SCORED/CONSENSUS/APPROVAL) are advisory-only and never merge.
VERIFIED = "VERIFIED"

#: The registry schema this module understands.
SUPPORTED_SCHEMA = 1

#: Default registry location, relative to the repository root.
DEFAULT_REGISTRY_PATH = Path("docs/governance/admitted-domains.json")


class RegistryError(ValueError):
    """The registry file is missing, not JSON, or structurally malformed."""


@dataclass(frozen=True)
class Domain:
    id: str
    verifier: str
    tier: str
    ratified: str


@dataclass(frozen=True)
class Supplier:
    package: str
    domain: str
    supplier: str
    ratified: str


@dataclass(frozen=True)
class Registry:
    schema_version: int
    domains: tuple[Domain, ...]
    targets: tuple[Supplier, ...]


def _require(condition: object, message: str) -> None:
    if not condition:
        raise RegistryError(message)


def parse_registry(data: object) -> Registry:
    """Validate a decoded registry document and return a typed :class:`Registry`.

    Raises :class:`RegistryError` on any structural problem (unknown
    ``schema_version``, non-object entry, missing required string field). Unknown
    keys (e.g. ``adr``, ``note``) are tolerated for auditability.
    """
    _require(isinstance(data, dict), "registry root must be a JSON object")
    assert isinstance(data, dict)  # narrow for type-checkers
    version = data.get("schema_version")
    _require(
        version == SUPPORTED_SCHEMA,
        f"unsupported schema_version {version!r} (expected {SUPPORTED_SCHEMA})",
    )

    domains: list[Domain] = []
    raw_domains = data.get("domains", [])
    _require(isinstance(raw_domains, list), "'domains' must be a list")
    for entry in raw_domains:
        _require(isinstance(entry, dict), "each domain entry must be an object")
        for key in ("id", "verifier", "tier"):
            value = entry.get(key)
            _require(
                isinstance(value, str) and value, f"domain entry missing string '{key}'"
            )
        domains.append(
            Domain(
                id=entry["id"],
                verifier=entry["verifier"],
                tier=entry["tier"],
                ratified=str(entry.get("ratified", "")),
            )
        )

    targets: list[Supplier] = []
    raw_targets = data.get("targets", [])
    _require(isinstance(raw_targets, list), "'targets' must be a list")
    for entry in raw_targets:
        _require(isinstance(entry, dict), "each target entry must be an object")
        for key in ("package", "domain", "supplier"):
            value = entry.get(key)
            _require(
                isinstance(value, str) and value, f"target entry missing string '{key}'"
            )
        targets.append(
            Supplier(
                package=entry["package"],
                domain=entry["domain"],
                supplier=entry["supplier"],
                ratified=str(entry.get("ratified", "")),
            )
        )

    return Registry(
        schema_version=SUPPORTED_SCHEMA, domains=tuple(domains), targets=tuple(targets)
    )


def load_registry(path: Path | str = DEFAULT_REGISTRY_PATH) -> Registry:
    """Load and validate the registry from disk. Raises :class:`RegistryError`."""
    path = Path(path)
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise RegistryError(f"registry not found: {path}") from exc
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RegistryError(f"registry is not valid JSON: {exc}") from exc
    return parse_registry(data)


def domain_admissible(domain_id: str, registry: Registry) -> bool:
    """True iff ``domain_id`` is registered and kernel-grade (``tier == VERIFIED``)."""
    return any(
        d.id == domain_id and d.tier == VERIFIED for d in registry.domains
    )


def target_curated(package: str, registry: Registry) -> Supplier | None:
    """The vetted :class:`Supplier` for ``package``, else ``None``.

    A package not present in the registry's ``targets`` is self-minted → not curated;
    SPEC-081-A check 2 and SPEC-078-A's credit rule both reject that.
    """
    for target in registry.targets:
        if target.package == package:
            return target
    return None
