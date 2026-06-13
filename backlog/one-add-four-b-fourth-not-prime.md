# one-add-four-b-fourth-not-prime

For every natural b > 1, 1 + 4b⁴ is not prime; by the Sophie Germain factorization 1 + 4b⁴ = (2b²+2b+1)(2b²−2b+1), with both factors exceeding 1.

- **Source:** classic identities (compositeness-via-factorization — the Sophie Germain a=1 corollary)
- **Reference:** The a=1 case of Sophie Germain's identity a⁴+4b⁴ = (a²−2ab+2b²)(a²+2ab+2b²); a companion to the proved `not-prime-pow-four-add-four` (which is the b=1 case n⁴+4). Sierpiński, Elementary Theory of Numbers.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13). mathlib has the Sophie Germain *identity* (`Algebra/Ring/Identities.pow_four_add_four_mul_pow_four'`) but not this compositeness corollary.
- **Difficulty:** 3
- **Decomposition sketch:** Specialise mathlib's `pow_four_add_four_mul_pow_four'` at a=1 (or `ring`-derive) to 1+4b⁴ = (2b²−2b+1)(2b²+2b+1); for b > 1 both factors exceed 1 (2b²−2b+1 = 2b(b−1)+1 ≥ 5), so the number is composite (`Nat.not_prime_mul`). 2 steps.
