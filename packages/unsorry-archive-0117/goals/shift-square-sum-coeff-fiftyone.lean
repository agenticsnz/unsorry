import Mathlib

theorem shift_square_sum_coeff_fiftyone (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 51) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 51 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 51 ^ 2 := by
  sorry
