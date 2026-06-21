# coprime-3n1-4n1

3n+1 and 4n+1 are always coprime.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** 3n+1 and 4n+1 are always coprime. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 4*(3n+1) - 3*(4n+1) = 1, so the gcd divides 1; reduce via Nat.Coprime gcd subtraction lemmas. Verified to build (lake env lean).
