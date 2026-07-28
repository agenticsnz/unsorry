import Mathlib

theorem shift_square_sum_coeff_sixtytwo (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 62) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 62 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 62 ^ 2 := by
  sorry
