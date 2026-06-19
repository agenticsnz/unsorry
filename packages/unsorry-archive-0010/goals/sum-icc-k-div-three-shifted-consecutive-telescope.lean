import Mathlib

open Finset
theorem sum_icc_k_div_three_shifted_consecutive_telescope (n : ℕ) :
    ∑ k ∈ Icc 1 n, (k : ℝ) / ((k + 1) * (k + 2) * (k + 3))
      = 1 / 4 + 1 / (2 * (n + 2)) - 3 / (2 * (n + 3)) := by
  sorry
