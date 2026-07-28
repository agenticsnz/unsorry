import Mathlib

theorem shift_square_sum_coeff_thirtytwo (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 32) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 32 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 32 ^ 2 := by
  sorry
