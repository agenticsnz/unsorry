import Mathlib

theorem shift_square_sum_coeff_fortyone (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 41) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 41 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 41 ^ 2 := by
  sorry
