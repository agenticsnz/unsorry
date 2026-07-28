import Mathlib

theorem shift_square_sum_coeff_seventyeight (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 78) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 78 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 78 ^ 2 := by
  sorry
