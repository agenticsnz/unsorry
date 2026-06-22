# dvd-510-pow-seventeen-sub-self

510 divides n^17 minus n for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** 510 divides n^17 minus n for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** ∀ x : ZMod 510, x^17 - x = 0 by decide; ZMod.intCast_zmod_eq_zero_iff_dvd. 510 = 2·3·5·17. Verified to build (lake env lean).
