import Mathlib

open Finset in
theorem sum_range_two_k_sub_n_mul_choose_sq_eq_zero (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (2 * (k : ℤ) - n) * (n.choose k : ℤ) ^ 2 = 0 := by
  sorry
