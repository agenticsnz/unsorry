# dvd-fortyeight-coprime-six-pow-four-sub-one

For every integer n divisible by neither 2 nor 3, 48 divides n^4 minus 1.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** For every integer n divisible by neither 2 nor 3, 48 divides n^4 minus 1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** n coprime to 6 means its ZMod 48 residue is a unit; ∀ x : ZMod 48 that is a unit, x^4 = 1 (decide over the unit residues), then transfer; coprimality hyps select the unit residues. Verified to build (lake env lean).
