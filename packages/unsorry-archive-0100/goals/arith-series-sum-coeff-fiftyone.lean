import Mathlib

theorem arith_series_sum_coeff_fiftyone (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 51) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 51 * (n : ℤ) := by
  sorry
