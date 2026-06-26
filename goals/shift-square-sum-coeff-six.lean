import Mathlib

theorem shift_square_sum_coeff_six (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 6) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 6 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 6 ^ 2 := by
  sorry
