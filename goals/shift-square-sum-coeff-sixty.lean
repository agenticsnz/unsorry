import Mathlib

theorem shift_square_sum_coeff_sixty (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 60) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 60 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 60 ^ 2 := by
  sorry
