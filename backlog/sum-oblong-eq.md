# sum-oblong-eq

Three times the sum of the first n oblong (pronic) numbers k(k+1) equals (n-1)n(n+1).

- **Source:** #400 Identity Engine (ADR-043) — figurate family.
- **Reference:** Three times the sum of the first n oblong (pronic) numbers k(k+1) equals (n-1)n(n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Induction on n; Finset.sum_range_succ then reduce to the IH via push_cast and a linear combination/ring.
