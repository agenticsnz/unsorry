# dvd-210-pow-fifteen-sub-pow-three

The integer 210 = 2·3·5·7 divides n^15 - n^3 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** The integer 210 = 2·3·5·7 divides n^15 - n^3 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** ZMod 210 decide bridge; λ(210)=12 divides 12 so n^15≡n^3, decidable over the 210 residues. Verified to build (lake env lean).
