import Mathlib

theorem shift_square_sum_coeff_seventysix (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 76) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 76 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 76 ^ 2 := by
  sorry
