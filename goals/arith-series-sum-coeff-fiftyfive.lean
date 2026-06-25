import Mathlib

theorem arith_series_sum_coeff_fiftyfive (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 55) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 55 * (n : ℤ) := by
  sorry
