import Mathlib

theorem arith_series_sum_coeff_fiftyeight (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 58) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 58 * (n : ℤ) := by
  sorry
