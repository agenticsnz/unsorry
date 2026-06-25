import Mathlib

theorem shift_square_sum_coeff_eight (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 8) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 8 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 8 ^ 2 := by
  sorry
