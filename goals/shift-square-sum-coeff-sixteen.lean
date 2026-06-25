import Mathlib

theorem shift_square_sum_coeff_sixteen (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 16) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 16 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 16 ^ 2 := by
  sorry
