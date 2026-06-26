import Mathlib

theorem shift_square_sum_coeff_twentythree (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 23) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 23 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 23 ^ 2 := by
  sorry
