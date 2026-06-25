import Mathlib

theorem arith_series_sum_coeff_fifty (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 50) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 50 * (n : ℤ) := by
  sorry
