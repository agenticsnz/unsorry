# dvd-66-pow-twentyone-sub-pow-eleven

For every integer n, 66 divides n to the 21st power minus n to the 11th power.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** For every integer n, 66 divides n to the 21st power minus n to the 11th power. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 66 = 2·3·11; decide n^21=n^11 in ZMod 2, ZMod 3, ZMod 11, combine by coprimality. Verified to build (lake env lean).
