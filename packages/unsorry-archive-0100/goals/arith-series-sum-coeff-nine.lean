import Mathlib

theorem arith_series_sum_coeff_nine (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 9) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 9 * (n : ℤ) := by
  sorry
