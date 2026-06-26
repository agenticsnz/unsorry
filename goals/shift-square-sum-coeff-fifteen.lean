import Mathlib

theorem shift_square_sum_coeff_fifteen (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 15) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 15 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 15 ^ 2 := by
  sorry
