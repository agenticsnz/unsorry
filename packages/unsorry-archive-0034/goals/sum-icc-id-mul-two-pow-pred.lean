import Mathlib

theorem sum_icc_id_mul_two_pow_pred (n : ℕ) : (∑ k ∈ Finset.Icc 1 n, (k : ℤ) * 2 ^ (k - 1)) = (n - 1) * 2 ^ n + 1 := by
  sorry
