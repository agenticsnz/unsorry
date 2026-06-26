import Mathlib

theorem shift_square_sum_coeff_fortyseven (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 47) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 47 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 47 ^ 2 := by
  sorry
