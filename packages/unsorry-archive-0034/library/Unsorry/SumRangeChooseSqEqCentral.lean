import Mathlib

theorem sum_range_choose_sq_eq_central (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (n.choose k) ^ 2 = (2 * n).choose n := by
  exact Nat.sum_range_choose_sq n
