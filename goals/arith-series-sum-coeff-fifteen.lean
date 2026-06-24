import Mathlib

theorem arith_series_sum_coeff_fifteen (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 15) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 15 * (n : ℤ) := by
  sorry
