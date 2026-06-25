import Mathlib

theorem shift_square_sum_coeff_fortyfour (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 44) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 44 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 44 ^ 2 := by
  sorry
