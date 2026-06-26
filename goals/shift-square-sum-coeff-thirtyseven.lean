import Mathlib

theorem shift_square_sum_coeff_thirtyseven (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 37) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 37 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 37 ^ 2 := by
  sorry
