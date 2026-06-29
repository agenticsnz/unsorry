import Mathlib

theorem shift_square_sum_coeff_seventyfour (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 74) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 74 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 74 ^ 2 := by
  sorry
