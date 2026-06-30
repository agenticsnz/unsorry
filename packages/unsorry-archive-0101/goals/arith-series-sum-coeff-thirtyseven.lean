import Mathlib

theorem arith_series_sum_coeff_thirtyseven (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 37) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 37 * (n : ℤ) := by
  sorry
