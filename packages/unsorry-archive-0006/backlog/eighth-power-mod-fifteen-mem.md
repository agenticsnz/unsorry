# eighth-power-mod-fifteen-mem

Every eighth power is congruent to only 0, 1, 6 or 10 modulo 15.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** Every eighth power is congruent to only 0, 1, 6 or 10 modulo 15. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** By CRT mod 3 and 5 the eighth powers collapse to four values; Nat.pow_mod then decide over n % 15. Verified to build (lake env lean).
