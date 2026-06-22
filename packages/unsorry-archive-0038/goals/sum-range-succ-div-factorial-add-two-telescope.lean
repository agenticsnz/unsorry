import Mathlib

theorem sum_range_succ_div_factorial_add_two_telescope (n : ℕ) : (∑ k ∈ Finset.range n, ((k : ℚ) + 1) / Nat.factorial (k + 2)) = 1 - 1 / Nat.factorial (n + 1) := by
  sorry
