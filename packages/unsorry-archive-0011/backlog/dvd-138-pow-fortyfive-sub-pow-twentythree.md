# dvd-138-pow-fortyfive-sub-pow-twentythree

138 divides n^45 - n^23 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** 138 divides n^45 - n^23 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Write n^45-n^23 = n^23(n^22-1); for each prime p|138 reduce mod p with ZMod decide (covering both n coprime and divisible cases), then coprime-combine. Verified to build (lake env lean) at sourcing.
