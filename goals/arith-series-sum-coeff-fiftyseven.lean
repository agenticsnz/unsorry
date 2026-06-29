import Mathlib

theorem arith_series_sum_coeff_fiftyseven (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 57) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 57 * (n : ℤ) := by
  sorry
