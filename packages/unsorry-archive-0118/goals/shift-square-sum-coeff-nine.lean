import Mathlib

theorem shift_square_sum_coeff_nine (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 9) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 9 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 9 ^ 2 := by
  sorry
