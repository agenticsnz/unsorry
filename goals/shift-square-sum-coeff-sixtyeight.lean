import Mathlib

theorem shift_square_sum_coeff_sixtyeight (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 68) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 68 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 68 ^ 2 := by
  sorry
