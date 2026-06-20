# two-fourth-powers-zmod-five-ne-three-four

A sum of two integer fourth powers is never congruent to 3 or 4 modulo 5.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog.
- **Reference:** A sum of two integer fourth powers is never congruent to 3 or 4 modulo 5. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** decide over the finite ZMod 5 × ZMod 5 domain (fourth powers are only 0 or 1 mod 5). Verified to build (lake env lean) at sourcing.
