import Mathlib

theorem shift_square_sum_coeff_ten (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 10) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 10 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 10 ^ 2 := by
  sorry
