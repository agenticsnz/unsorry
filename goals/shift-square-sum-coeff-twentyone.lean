import Mathlib

theorem shift_square_sum_coeff_twentyone (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 21) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 21 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 21 ^ 2 := by
  sorry
