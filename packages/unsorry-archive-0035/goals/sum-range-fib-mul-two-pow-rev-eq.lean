import Mathlib

theorem sum_range_fib_mul_two_pow_rev_eq (n : ℕ) : ∑ k ∈ Finset.range (n + 1), Nat.fib k * 2 ^ (n - k) + Nat.fib (n + 3) = 2 ^ (n + 1) := by
  sorry
