# dvd-282-pow-fortyseven-sub-self

282 divides n^47 - n for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog.
- **Reference:** 282 divides n^47 - n for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 282 = 2*3*47; each prime divides n^47-n by Fermat (set maxRecDepth for ZMod 47 decide); CRT-combine the three coprime factors. Verified to build (lake env lean) at sourcing.
