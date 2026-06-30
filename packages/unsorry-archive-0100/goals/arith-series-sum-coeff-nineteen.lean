import Mathlib

theorem arith_series_sum_coeff_nineteen (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 19) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 19 * (n : ℤ) := by
  sorry
