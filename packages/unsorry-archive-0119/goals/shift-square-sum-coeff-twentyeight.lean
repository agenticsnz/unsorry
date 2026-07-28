import Mathlib

theorem shift_square_sum_coeff_twentyeight (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 28) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 28 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 28 ^ 2 := by
  sorry
