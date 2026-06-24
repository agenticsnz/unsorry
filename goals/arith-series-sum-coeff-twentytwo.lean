import Mathlib

theorem arith_series_sum_coeff_twentytwo (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 22) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 22 * (n : ℤ) := by
  sorry
