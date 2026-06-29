# dvd-66-pow-thirtyone-sub-pow-eleven

66 divides n^31 - n^11 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** 66 divides n^31 - n^11 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 66 = 2*3*11; n^31-n^11 = n^11(n^20-1), gap 20 divisible by each p-1; ZMod decide per prime then coprime-combine. Verified to build (lake env lean) at sourcing.
