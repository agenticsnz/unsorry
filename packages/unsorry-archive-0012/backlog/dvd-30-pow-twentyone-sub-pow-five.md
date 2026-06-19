# dvd-30-pow-twentyone-sub-pow-five

30 divides n^21 - n^5 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** 30 divides n^21 - n^5 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 30 = 2*3*5; n^21-n^5 = n^5(n^16-1), gap 16 divisible by each p-1; ZMod decide mod 2,3,5 and coprime-combine. Verified to build (lake env lean) at sourcing.
