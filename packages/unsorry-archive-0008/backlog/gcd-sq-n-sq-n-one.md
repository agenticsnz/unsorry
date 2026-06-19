# gcd-sq-n-sq-n-one

n squared is coprime to n squared plus n plus one.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** n squared is coprime to n squared plus n plus one. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** n^2 coprime to n+1 and to n^2+n+1 (each via add-multiple reduction); combine with Nat.Coprime.pow / mul. Verified to build (lake env lean).
