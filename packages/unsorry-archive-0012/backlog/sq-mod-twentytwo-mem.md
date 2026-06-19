# sq-mod-twentytwo-mem

Every perfect square modulo 22 is one of the twelve quadratic residues {0,1,3,4,5,9,11,12,14,15,16,20}.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every perfect square modulo 22 is one of the twelve quadratic residues {0,1,3,4,5,9,11,12,14,15,16,20}. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Nat.pow_mod to depend only on n % 22, then decide over all 22 residues. Verified to build (lake env lean).
