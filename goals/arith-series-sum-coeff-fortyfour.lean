import Mathlib

theorem arith_series_sum_coeff_fortyfour (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 44) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 44 * (n : ℤ) := by
  sorry
