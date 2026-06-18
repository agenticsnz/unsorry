# gcd-three-pow-succ-three-pow-add-one

Three to the n+1 is coprime to three to the n plus one.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** Three to the n+1 is coprime to three to the n plus one. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 3^(n+1) is a power of 3; show 3 is coprime to 3^n+1 (it is 1 mod 3), then Nat.Coprime.pow_left. Verified to build (lake env lean).
