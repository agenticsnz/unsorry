import Mathlib

theorem prod_icc_k_sq_div_pred_mul_succ_telescope (n : ℕ) (hn : 2 ≤ n) :
    ∏ k ∈ Finset.Icc 2 n, ((k : ℚ)^2 / ((k - 1) * (k + 1))) = 2 * (n : ℚ) / ((n : ℚ) + 1) := by
  sorry
