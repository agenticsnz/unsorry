# aurifeuillian-quartic-dvd

The quadratic a²+a+1 always divides a⁴+a²+1.

- **Source:** #400 Identity Engine (ADR-043) — algebraic family.
- **Reference:** The quadratic a²+a+1 always divides a⁴+a²+1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Witness cofactor a²−a+1: (a²+a+1)(a²−a+1)=a⁴+a²+1 by ring.
