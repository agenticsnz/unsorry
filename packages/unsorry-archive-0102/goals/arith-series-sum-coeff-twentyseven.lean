import Mathlib

theorem arith_series_sum_coeff_twentyseven (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 27) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 27 * (n : ℤ) := by
  sorry
