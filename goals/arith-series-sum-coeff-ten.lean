import Mathlib

theorem arith_series_sum_coeff_ten (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 10) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 10 * (n : ℤ) := by
  sorry
