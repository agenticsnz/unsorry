import Mathlib

theorem sum_range_succ_mul_factorial_eq (n : ℕ) : ∑ k ∈ Finset.range n, (k + 1) * Nat.factorial (k + 1) = Nat.factorial (n + 1) - 1 := by
  sorry
