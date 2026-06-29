import Mathlib

theorem arith_series_sum_coeff_seventyfive (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 75) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 75 * (n : ℤ) := by
  sorry
