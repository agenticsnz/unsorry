import Mathlib

theorem sum_range_succ_mul_choose_sq_eq (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), (k + 1) * n.choose k ^ 2 = (n + 2) * (2 * n).choose n := by
  sorry
