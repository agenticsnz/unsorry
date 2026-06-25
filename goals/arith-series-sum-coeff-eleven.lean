import Mathlib

theorem arith_series_sum_coeff_eleven (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 11) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 11 * (n : ℤ) := by
  sorry
