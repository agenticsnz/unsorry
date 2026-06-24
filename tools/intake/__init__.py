"""Curated-package intake (ADR-081 / SPEC-081-A).

``skeleton-validate`` admits a sponsor-registered skeleton package into the queue:
it checks the package is *structurally* a real, consumable, curated skeleton — a
type-checking top statement, well-formed open-goal obligations, sound acyclic
decomposition edges rooted at the top, vetted-supplier provenance — before any
obligation is queued. Mathematical correctness stays the kernel's job at Gate A.
"""
