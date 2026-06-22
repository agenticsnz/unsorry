import Mathlib

theorem prod_icc_k_mul_add_two_div_succ_sq_telescope_half (n : ℕ) (hn : 1 ≤ n) :
    ∏ k ∈ Finset.Icc 1 n, ((k : ℝ) * ((k : ℝ) + 2)) / ((k : ℝ) + 1) ^ 2
      = ((n : ℝ) + 2) / (2 * ((n : ℝ) + 1)) := by
  sorry
