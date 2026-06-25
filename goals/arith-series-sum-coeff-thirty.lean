import Mathlib

theorem arith_series_sum_coeff_thirty (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 30) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 30 * (n : ℤ) := by
  sorry
