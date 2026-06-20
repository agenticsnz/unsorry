# eighth-power-mod-sixteen-mem

Every eighth power is congruent to only 0 or 1 modulo 16.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every eighth power is congruent to only 0 or 1 modulo 16. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Odd^8 ≡ 1 and even^8 ≡ 0 mod 16; Nat.pow_mod then decide over n % 16. Verified to build (lake env lean).
