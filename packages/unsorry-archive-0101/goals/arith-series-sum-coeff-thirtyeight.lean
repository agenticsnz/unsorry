import Mathlib

theorem arith_series_sum_coeff_thirtyeight (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 38) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 38 * (n : ℤ) := by
  sorry
