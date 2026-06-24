import Mathlib

theorem shift_square_sum_coeff_fortysix (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 46) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 46 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 46 ^ 2 := by
  sorry
