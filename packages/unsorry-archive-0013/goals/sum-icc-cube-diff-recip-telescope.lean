import Mathlib

theorem sum_icc_cube_diff_recip_telescope (n : ℕ) (hn : 1 ≤ n) : (∑ k ∈ Finset.Icc 1 n, (3 * (k : ℚ) ^ 2 + 3 * k + 1) / (k ^ 3 * (k + 1) ^ 3)) = 1 - 1 / ((n : ℚ) + 1) ^ 3 := by
  sorry
