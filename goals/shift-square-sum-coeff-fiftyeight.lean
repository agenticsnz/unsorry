import Mathlib

theorem shift_square_sum_coeff_fiftyeight (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 58) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 58 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 58 ^ 2 := by
  sorry
