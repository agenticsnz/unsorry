# prime-pow-six-mod-504

For every prime p greater than 7, p^6 is congruent to 1 modulo 504.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** For every prime p greater than 7, p^6 is congruent to 1 modulo 504. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** Reduce mod 504=8·9·7 via CRT/ZMod units; for p coprime to 504, p is a unit whose order divides 6 in each factor (decide over coprime residues of ZMod 504). Verified to build (lake env lean).
