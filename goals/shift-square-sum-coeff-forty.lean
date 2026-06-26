import Mathlib

theorem shift_square_sum_coeff_forty (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 40) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 40 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 40 ^ 2 := by
  sorry
