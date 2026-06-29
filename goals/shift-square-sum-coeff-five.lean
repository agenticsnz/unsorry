import Mathlib

theorem shift_square_sum_coeff_five (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 5) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 5 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 5 ^ 2 := by
  sorry
