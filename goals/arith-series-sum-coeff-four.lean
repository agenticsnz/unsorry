import Mathlib

theorem arith_series_sum_coeff_four (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 4) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 4 * (n : ℤ) := by
  sorry
