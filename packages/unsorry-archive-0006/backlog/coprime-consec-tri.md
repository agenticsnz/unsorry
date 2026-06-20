# coprime-consec-tri

The odd number 2n+1 is coprime to the product n(n+1).

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The odd number 2n+1 is coprime to the product n(n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 2n+1 is coprime to n and to n+1 separately (each a Bezout 1-step), then Nat.Coprime.mul_right. Verified to build (lake env lean).
