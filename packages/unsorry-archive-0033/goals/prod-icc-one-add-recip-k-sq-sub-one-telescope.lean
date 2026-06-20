import Mathlib

theorem prod_icc_one_add_recip_k_sq_sub_one_telescope (n : ℕ) (hn : 2 ≤ n) : (∏ k ∈ Finset.Icc 2 n, (1 + 1 / ((k : ℚ) ^ 2 - 1))) = 2 * (n : ℚ) / (n + 1) := by
  sorry
