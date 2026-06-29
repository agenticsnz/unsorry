import Mathlib

theorem shift_square_sum_coeff_seventytwo (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 72) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 72 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 72 ^ 2 := by
  sorry
