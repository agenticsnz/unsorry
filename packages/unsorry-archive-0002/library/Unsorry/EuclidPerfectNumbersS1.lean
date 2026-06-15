import Mathlib

theorem sum_divisors_two_pow (k : ℕ) : ∑ d ∈ Nat.divisors (2 ^ k), d = 2 ^ (k + 1) - 1 := by
  rw [Nat.sum_divisors_prime_pow Nat.prime_two]
  rw [Nat.geomSum_eq (le_refl 2)]
  norm_num
