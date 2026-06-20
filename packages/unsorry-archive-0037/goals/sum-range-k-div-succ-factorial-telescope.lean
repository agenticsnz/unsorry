import Mathlib

theorem sum_range_k_div_succ_factorial_telescope (n : ℕ) : (∑ k ∈ Finset.range n, (k : ℚ) / Nat.factorial (k + 1)) = 1 - 1 / Nat.factorial n := by
  sorry
