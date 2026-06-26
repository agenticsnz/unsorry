import Mathlib

theorem shift_square_sum_coeff_twentytwo (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 22) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 22 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 22 ^ 2 := by
  sorry
