import Mathlib

theorem arith_series_sum_coeff_thirtynine (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 39) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 39 * (n : ℤ) := by
  sorry
