# quartic-n4-plus-four-composite

n⁴+4 factors explicitly as (n²-2n+2)(n²+2n+2), exhibiting both Sophie-Germain factors.

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** n⁴+4 factors explicitly as (n²-2n+2)(n²+2n+2), exhibiting both Sophie-Germain factors. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** exact ⟨_, _, by ring, rfl, rfl⟩. Verified to build (lake env lean).
