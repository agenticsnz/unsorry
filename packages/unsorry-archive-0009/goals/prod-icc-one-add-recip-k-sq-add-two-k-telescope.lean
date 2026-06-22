import Mathlib

theorem prod_icc_one_add_recip_k_sq_add_two_k_telescope (n : ℕ) (hn : 1 ≤ n) : (∏ k ∈ Finset.Icc 1 n, (1 + 1 / ((k : ℚ) ^ 2 + 2 * k))) = 2 * ((n : ℚ) + 1) / (n + 2) := by
  sorry
