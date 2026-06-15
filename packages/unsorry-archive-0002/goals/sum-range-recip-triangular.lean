import Mathlib

theorem sum_range_two_div_succ_mul_succ_succ (n : ℕ) :
    ∑ k ∈ Finset.range n, (2 : ℚ) / (((k : ℚ) + 1) * ((k : ℚ) + 2))
      = 2 * (n : ℚ) / ((n : ℚ) + 1) := by
  sorry
