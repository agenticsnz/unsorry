import Mathlib

theorem shift_square_sum_coeff_twentyfour (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 24) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 24 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 24 ^ 2 := by
  sorry
