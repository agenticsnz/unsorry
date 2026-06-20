# dvd-240-pow-eight-sub-pow-four

240 divides n^8 minus n^4 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** 240 divides n^8 minus n^4 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** ∀ x : ZMod 240, x^8 - x^4 = 0 by decide; transfer via intCast_zmod_eq_zero_iff_dvd. Verified to build (lake env lean).
