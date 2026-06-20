# sq-mod-ten-ne-two-three-seven-eight

No perfect square ends in the decimal digit 2, 3, 7, or 8.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog (#610).
- **Reference:** No perfect square ends in the decimal digit 2, 3, 7, or 8. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Nat.pow_mod then interval_cases / decide over n % 10 to rule out the four non-residue digits. Verified to build (lake env lean).
