import Mathlib

theorem arith_series_sum_coeff_twentysix (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 26) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 26 * (n : ℤ) := by
  sorry
