# dvd-42-pow-twentyfive-sub-pow-seven

42 divides n^25 - n^7 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** 42 divides n^25 - n^7 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 42 = 2*3*7; gap 18 is a multiple of each p-1, decide n^25≡n^7 over ZMod 2,3,7 and combine via coprime dvd product. Verified to build (lake env lean) at sourcing.
