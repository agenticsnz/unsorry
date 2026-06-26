# dvd-510-pow-fortynine-sub-pow-seventeen

510 divides n^49 - n^17 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** 510 divides n^49 - n^17 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 510 = 2*3*5*17; the exponent gap 32 is divisible by each (p-1) so n^49≡n^17 mod p by ZMod decide; combine coprime factors. Verified to build (lake env lean) at sourcing.
