import Mathlib

theorem sum_icc_recip_k_sq_sub_one_telescope (n : ℕ) (hn : 2 ≤ n) : (∑ k ∈ Finset.Icc 2 n, (1 : ℚ) / (k ^ 2 - 1)) = 3 / 4 - (2 * (n : ℚ) + 1) / (2 * n * (n + 1)) := by
  sorry
