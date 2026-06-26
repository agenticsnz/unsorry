import Mathlib

theorem shift_square_sum_coeff_four (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 4) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 4 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 4 ^ 2 := by
  sorry
