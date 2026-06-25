import Mathlib

theorem shift_square_sum_coeff_two (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 2) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 2 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 2 ^ 2 := by
  sorry
