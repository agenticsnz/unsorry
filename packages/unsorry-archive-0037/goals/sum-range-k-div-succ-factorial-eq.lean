import Mathlib

theorem sum_range_k_div_succ_factorial_eq (n : ℕ) : ∑ k ∈ Finset.range n, (k : ℚ) / (Nat.factorial (k + 1) : ℚ) = 1 - 1 / (Nat.factorial n : ℚ) := by
  sorry
