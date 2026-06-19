# dvd-170-pow-seventeen-sub-self

For every integer n, 170 divides n raised to the 17th power minus n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** For every integer n, 170 divides n raised to the 17th power minus n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 170 = 2·5·17; reduce to ZMod 2, ZMod 5, ZMod 17 and decide, then combine by coprimality. Verified to build (lake env lean).
