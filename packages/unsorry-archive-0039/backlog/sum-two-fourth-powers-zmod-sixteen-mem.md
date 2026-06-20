# sum-two-fourth-powers-zmod-sixteen-mem

A sum of two integer fourth powers is congruent to 0, 1, or 2 modulo 16.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** A sum of two integer fourth powers is congruent to 0, 1, or 2 modulo 16. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** cast to ZMod 16, decide over ZMod 16 × ZMod 16 since each fourth power is 0 or 1. Verified to build (lake env lean).
