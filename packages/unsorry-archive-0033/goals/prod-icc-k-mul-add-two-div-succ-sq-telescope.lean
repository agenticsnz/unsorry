import Mathlib

theorem prod_icc_k_mul_add_two_div_succ_sq_telescope (n : ℕ) (hn : 1 ≤ n) : (∏ k ∈ Finset.Icc 1 n, ((k : ℚ) * (k + 2)) / (k + 1) ^ 2) = ((n : ℚ) + 2) / (2 * (n + 1)) := by
  sorry
