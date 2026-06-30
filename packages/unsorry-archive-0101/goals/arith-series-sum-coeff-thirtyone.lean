import Mathlib

theorem arith_series_sum_coeff_thirtyone (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 31) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 31 * (n : ℤ) := by
  sorry
