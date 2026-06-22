import Mathlib

theorem sum_icc_five_k_sub_two_mul_three_pow_pred_closed (n : ℕ) :
    4 * ∑ k ∈ Finset.Icc 1 n, ((5 * (k : ℤ) - 2) * 3 ^ (k - 1)) =
      (10 * (n : ℤ) - 9) * 3 ^ n + 9 := by
  sorry
