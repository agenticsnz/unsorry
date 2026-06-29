import Mathlib

theorem shift_square_sum_coeff_fiftyfive (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 55) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 55 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 55 ^ 2 := by
  sorry
