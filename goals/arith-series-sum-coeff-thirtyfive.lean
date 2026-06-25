import Mathlib

theorem arith_series_sum_coeff_thirtyfive (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 35) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 35 * (n : ℤ) := by
  sorry
