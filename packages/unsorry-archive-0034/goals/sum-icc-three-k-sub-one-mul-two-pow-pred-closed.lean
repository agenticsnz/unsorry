import Mathlib

theorem sum_icc_three_k_sub_one_mul_two_pow_pred_closed (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, ((3 * (k : ℤ) - 1) * 2 ^ (k - 1)) =
      (3 * (n : ℤ) - 4) * 2 ^ n + 4 := by
  sorry
