import Mathlib

theorem shift_square_sum_coeff_thirty (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 30) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 30 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 30 ^ 2 := by
  sorry
