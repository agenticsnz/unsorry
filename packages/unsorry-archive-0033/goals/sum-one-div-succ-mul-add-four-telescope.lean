import Mathlib

theorem sum_one_div_succ_mul_add_four_telescope (n : ℕ) : (∑ k ∈ Finset.range n, (3 : ℚ) / ((k + 1) * (k + 4))) = 11 / 6 - 1 / ((n : ℚ) + 1) - 1 / (n + 2) - 1 / (n + 3) := by
  sorry
