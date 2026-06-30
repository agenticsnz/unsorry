import Mathlib

theorem arith_series_sum_coeff_eighty (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 80) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 80 * (n : ℤ) := by
  sorry
