import Mathlib

theorem arith_series_sum_coeff_seventyone (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 71) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 71 * (n : ℤ) := by
  sorry
