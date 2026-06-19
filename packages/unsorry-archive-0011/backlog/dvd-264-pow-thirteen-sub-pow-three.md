# dvd-264-pow-thirteen-sub-pow-three

The integer 264 = 2^3·3·11 divides n^13 - n^3 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** The integer 264 = 2^3·3·11 divides n^13 - n^3 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** ZMod 264 decide bridge on x^13 - x^3 = 0; 2^3 forces the n^3 factor, λ(odd part)=10 divides 10 for the n^10 lift. Verified to build (lake env lean).
