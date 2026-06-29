import Mathlib

theorem shift_square_sum_coeff_thirtyfive (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 35) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 35 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 35 ^ 2 := by
  sorry
