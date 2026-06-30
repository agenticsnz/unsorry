import Mathlib

theorem shift_square_sum_coeff_nineteen (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 19) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 19 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 19 ^ 2 := by
  sorry
