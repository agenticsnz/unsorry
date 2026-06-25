import Mathlib

theorem arith_series_sum_coeff_three (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 3) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 3 * (n : ℤ) := by
  sorry
