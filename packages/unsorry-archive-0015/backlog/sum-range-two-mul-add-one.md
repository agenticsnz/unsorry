# sum-range-two-mul-add-one

The sum of the first n odd numbers ∑_{k<n}(2k+1) equals n².

- **Source:** #400 Identity Engine (ADR-043) — figurate family.
- **Reference:** The sum of the first n odd numbers ∑_{k<n}(2k+1) equals n². Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** induction; Finset.sum_range_succ; ring. Verified to build (lake env lean).
