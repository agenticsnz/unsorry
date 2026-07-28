import Mathlib

theorem shift_square_sum_coeff_eleven (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 11) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 11 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 11 ^ 2 := by
  sorry
