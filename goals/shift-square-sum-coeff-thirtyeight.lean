import Mathlib

theorem shift_square_sum_coeff_thirtyeight (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 38) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 38 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 38 ^ 2 := by
  sorry
