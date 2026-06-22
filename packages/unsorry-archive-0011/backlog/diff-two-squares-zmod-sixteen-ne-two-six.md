# diff-two-squares-zmod-sixteen-ne-two-six

A difference of two integer squares is never congruent to 2, 6, 10, or 14 modulo 16.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog.
- **Reference:** A difference of two integer squares is never congruent to 2, 6, 10, or 14 modulo 16. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** decide over the finite ZMod 16 × ZMod 16 domain. Verified to build (lake env lean) at sourcing.
