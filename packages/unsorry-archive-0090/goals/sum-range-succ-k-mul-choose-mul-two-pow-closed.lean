import Mathlib

theorem sum_range_succ_k_mul_choose_mul_two_pow_closed (n : ℕ) : 3 * ∑ k ∈ Finset.range (n + 1), (k + 1) * n.choose k * 2 ^ k = (2 * n + 3) * 3 ^ n := by
  sorry
