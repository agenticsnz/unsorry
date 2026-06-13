# pow-four-add-sq-add-one-not-prime

For every natural n > 1, n⁴ + n² + 1 is not prime; it factors as (n²+n+1)(n²−n+1) with both factors exceeding 1.

- **Source:** classic identities (compositeness-via-factorization — the **capstone**; compounds on `pow-four-add-sq-add-one-factor`)
- **Reference:** Classic olympiad compositeness result, the x⁴+x²+1 analogue of the proved `not-prime-pow-four-add-four` (Sophie Germain). Engel, Problem-Solving Strategies (divisibility/compositeness).
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 3
- **Decomposition sketch:** Apply the factorization leaf `pow-four-add-sq-add-one-factor` (over ℕ: n⁴+n²+1 = (n²+n+1)(n²−n+1)); for n > 1 both factors exceed 1 (n²−n+1 = n(n−1)+1 ≥ 3, n²+n+1 ≥ 7), so the number is a product of two factors > 1, hence not prime (`Nat.not_prime_mul` / `Nat.Prime` def). 2 steps, reusing the factorization leaf. Mirrors the proved `not-prime-pow-four-add-four`.
