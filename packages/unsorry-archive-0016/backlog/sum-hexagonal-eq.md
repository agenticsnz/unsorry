# sum-hexagonal-eq

Six times the sum of hexagonal-type terms k(2k-1) over range n equals (n-1)n(4n-5).

- **Source:** #400 Identity Engine (ADR-043) — figurate family.
- **Reference:** Six times the sum of hexagonal-type terms k(2k-1) over range n equals (n-1)n(4n-5). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Induction over ℤ; peel last term, push_cast, nlinarith closes the cubic identity using the IH.
