"""Domain-admission governance (ADR-080 / SPEC-080-A).

The single source of truth for *which domains and curated targets are admitted to
the trustless commons*. :mod:`tools.governance.admission` parses the auditable
registry (``docs/governance/admitted-domains.json``) and exposes the two pure
predicates the intake path (SPEC-081-A) and the credit pass (SPEC-078-A) consult.
"""
