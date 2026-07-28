import Mathlib

theorem shift_square_sum_coeff_thirtythree (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 33) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 33 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 33 ^ 2 := by
  sorry
