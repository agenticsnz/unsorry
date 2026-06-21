# cube-mod-fourteen-mem

The cubic residues modulo 14 are exactly 0, 1, 6, 7, 8, and 13.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** The cubic residues modulo 14 are exactly 0, 1, 6, 7, 8, and 13. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Nat.pow_mod, case-split on n % 14, decide each residue branch. Verified to build (lake env lean).
