import Mathlib

theorem shift_square_sum_coeff_fiftythree (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 53) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 53 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 53 ^ 2 := by
  sorry
