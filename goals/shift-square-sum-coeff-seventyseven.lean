import Mathlib

theorem shift_square_sum_coeff_seventyseven (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 77) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 77 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 77 ^ 2 := by
  sorry
