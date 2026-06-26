import Mathlib

theorem shift_square_sum_coeff_twentyseven (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 27) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 27 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 27 ^ 2 := by
  sorry
