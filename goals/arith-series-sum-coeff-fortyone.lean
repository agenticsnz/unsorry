import Mathlib

theorem arith_series_sum_coeff_fortyone (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 41) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 41 * (n : ℤ) := by
  sorry
