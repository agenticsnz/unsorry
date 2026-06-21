# dvd-330-pow-twentythree-sub-pow-three

For every integer n, 330 divides n to the 23rd power minus n to the 3rd power.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** For every integer n, 330 divides n to the 23rd power minus n to the 3rd power. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 330 = 2·3·5·11; per-prime ZMod.decide of n^23=n^3, recombine via Nat.Coprime.mul_dvd. Verified to build (lake env lean) at sourcing.
