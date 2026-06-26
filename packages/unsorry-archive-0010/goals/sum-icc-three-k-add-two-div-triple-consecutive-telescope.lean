import Mathlib

theorem sum_icc_three_k_add_two_div_triple_consecutive_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n,
      ((3 * (k : ℚ) + 2) / ((k : ℚ) * ((k : ℚ) + 1) * ((k : ℚ) + 2)))
      = 2 - 1 / ((n : ℚ) + 1) - 2 / ((n : ℚ) + 2) := by
  sorry
