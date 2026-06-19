# pell-negative-brahmagupta-composition-generic-d

Brahmagupta composition of two solutions of the negative Pell equation x²−dy²=−1 produces a solution of the positive equation x²−dy²=1, since (−1)(−1)=1.

- **Source:** #400 Identity Engine (ADR-043) — Pell-equation family; promoted from candidate backlog.
- **Reference:** Brahmagupta composition of two solutions of the negative Pell equation x²−dy²=−1 produces a solution of the positive equation x²−dy²=1, since (−1)(−1)=1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** show LHS = (a²−d·b²)(c²−d·e²) by ring, then rewrite both hypotheses: (−1)·(−1)=1. Verified to build (lake env lean) at sourcing.
