# gcd-n3p1-np1-eq-np1

Since n+1 divides n^3+1, the gcd of n^3+1 and n+1 is n+1.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog.
- **Reference:** Since n+1 divides n^3+1, the gcd of n^3+1 and n+1 is n+1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Show (n+1) ∣ n^3+1 via the factorization n^3+1=(n+1)(n^2-n+1); then Nat.gcd_eq_right. Verified to build (lake env lean) at sourcing.
