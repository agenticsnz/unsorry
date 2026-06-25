import Mathlib

theorem arith_series_sum_coeff_twelve (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 12) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 12 * (n : ℤ) := by
  sorry
