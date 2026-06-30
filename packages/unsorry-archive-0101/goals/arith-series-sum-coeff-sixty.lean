import Mathlib

theorem arith_series_sum_coeff_sixty (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 60) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 60 * (n : ℤ) := by
  sorry
