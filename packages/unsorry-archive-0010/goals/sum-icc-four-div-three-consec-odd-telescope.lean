import Mathlib

theorem sum_icc_four_div_three_consec_odd_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n,
      (4 : ℝ) / (((2 * k - 1 : ℝ)) * (2 * k + 1) * (2 * k + 3)) =
      1 / 3 - 1 / ((2 * n + 1) * (2 * n + 3)) := by
  sorry
