# dvd-266-pow-nineteen-sub-self

The integer 266 = 2·7·19 divides n^19 - n for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** The integer 266 = 2·7·19 divides n^19 - n for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** ZMod 266 decide bridge with push_cast; (p-1) for 2,7,19 all divide 18 so n^19≡n. Verified to build (lake env lean).
