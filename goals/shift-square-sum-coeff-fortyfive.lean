import Mathlib

theorem shift_square_sum_coeff_fortyfive (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 45) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 45 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 45 ^ 2 := by
  sorry
