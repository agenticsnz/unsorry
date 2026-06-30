import Mathlib

theorem arith_series_sum_coeff_fortytwo (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 42) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 42 * (n : ℤ) := by
  sorry
