import Mathlib

theorem shift_square_sum_coeff_sixtythree (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 63) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 63 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 63 ^ 2 := by
  sorry
