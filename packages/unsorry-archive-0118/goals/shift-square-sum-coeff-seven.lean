import Mathlib

theorem shift_square_sum_coeff_seven (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 7) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 7 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 7 ^ 2 := by
  sorry
