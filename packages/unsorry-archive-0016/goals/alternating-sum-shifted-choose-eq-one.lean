import Mathlib

theorem alternating_sum_shifted_choose_eq_one (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ k * (n + 1).choose (k + 1) = 1 := by
  sorry
