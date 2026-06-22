# sum-range-recip-consecutive

The telescoping sum ∑_{k<n} 1/((k+1)(k+2)) equals n/(n+1) over ℚ.

- **Source:** #400 Identity Engine (ADR-043) — telescoping-sum family.
- **Reference:** Partial fractions 1/((k+1)(k+2)) = 1/(k+1) − 1/(k+2) telescope to n/(n+1). Not a named mathlib lemma.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** induction on n; Finset.sum_range_succ; positivity for nonzero denominators; field_simp; ring. Verified to build (lake env lean).
