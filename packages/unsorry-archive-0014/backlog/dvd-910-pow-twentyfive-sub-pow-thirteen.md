# dvd-910-pow-twentyfive-sub-pow-thirteen

For every integer n, 910 divides n to the 25th power minus n to the 13th power.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** For every integer n, 910 divides n to the 25th power minus n to the 13th power. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 910 = 2·5·7·13; per-prime ZMod.decide of n^25=n^13, recombine via coprime product dvd. Verified to build (lake env lean) at sourcing.
