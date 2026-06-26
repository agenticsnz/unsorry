import Mathlib

theorem shift_square_sum_coeff_sixtyseven (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 67) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 67 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 67 ^ 2 := by
  sorry
