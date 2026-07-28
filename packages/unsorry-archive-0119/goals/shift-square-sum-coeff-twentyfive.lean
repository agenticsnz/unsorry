import Mathlib

theorem shift_square_sum_coeff_twentyfive (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 25) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 25 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 25 ^ 2 := by
  sorry
