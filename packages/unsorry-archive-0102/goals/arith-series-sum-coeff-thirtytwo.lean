import Mathlib

theorem arith_series_sum_coeff_thirtytwo (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 32) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 32 * (n : ℤ) := by
  sorry
