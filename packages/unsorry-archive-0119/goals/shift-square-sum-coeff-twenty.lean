import Mathlib

theorem shift_square_sum_coeff_twenty (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 20) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 20 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 20 ^ 2 := by
  sorry
