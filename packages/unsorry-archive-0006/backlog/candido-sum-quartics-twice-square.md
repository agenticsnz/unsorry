# candido-sum-quartics-twice-square

Candido's identity: the sum of the fourth powers of a, b and a+b is always twice a perfect square.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** Candido's identity: the sum of the fourth powers of a, b and a+b is always twice a perfect square. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** exact ⟨a^2 + a*b + b^2, by ring⟩. Verified to build (lake env lean).
