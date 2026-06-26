# prime-pow-eight-mod-480

For every prime p greater than 5, p^8 is congruent to 1 modulo 480.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** For every prime p greater than 5, p^8 is congruent to 1 modulo 480. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 4
- **Decomposition sketch:** 480 = 32·3·5; for p coprime to 480 the residue's 8th power is 1 in each unit group; decide over coprime residues / ZMod CRT. Verified to build (lake env lean).
