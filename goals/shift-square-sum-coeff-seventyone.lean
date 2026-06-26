import Mathlib

theorem shift_square_sum_coeff_seventyone (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 71) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 71 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 71 ^ 2 := by
  sorry
