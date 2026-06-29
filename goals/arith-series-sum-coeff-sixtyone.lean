import Mathlib

theorem arith_series_sum_coeff_sixtyone (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 61) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 61 * (n : ℤ) := by
  sorry
