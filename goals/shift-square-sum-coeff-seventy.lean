import Mathlib

theorem shift_square_sum_coeff_seventy (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 70) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 70 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 70 ^ 2 := by
  sorry
