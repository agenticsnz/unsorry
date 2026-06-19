# prod-range-one-sub-recip-succ-sq

The product of (1 − 1/(k+1)²) for k from 1 to n equals (n+2)/(2(n+1)).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family; promoted from candidate backlog (#610).
- **Reference:** The product of (1 − 1/(k+1)²) for k from 1 to n equals (n+2)/(2(n+1)). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Induction; rewrite 1 − 1/(k+1)² = k(k+2)/(k+1)² and telescope, field_simp + ring. Verified to build (lake env lean).
