import Mathlib

theorem shift_square_sum_coeff_sixtyfour (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 64) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 64 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 64 ^ 2 := by
  sorry
