import Mathlib

theorem shift_square_sum_coeff_twentysix (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 26) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 26 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 26 ^ 2 := by
  sorry
