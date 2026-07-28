import Mathlib

theorem shift_square_sum_coeff_thirtynine (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 39) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 39 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 39 ^ 2 := by
  sorry
