import Mathlib

theorem shift_square_sum_coeff_fortynine (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 49) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 49 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 49 ^ 2 := by
  sorry
