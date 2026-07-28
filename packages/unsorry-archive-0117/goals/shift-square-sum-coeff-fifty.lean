import Mathlib

theorem shift_square_sum_coeff_fifty (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 50) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 50 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 50 ^ 2 := by
  sorry
