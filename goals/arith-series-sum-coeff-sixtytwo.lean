import Mathlib

theorem arith_series_sum_coeff_sixtytwo (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 62) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 62 * (n : ℤ) := by
  sorry
