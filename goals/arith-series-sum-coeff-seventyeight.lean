import Mathlib

theorem arith_series_sum_coeff_seventyeight (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 78) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 78 * (n : ℤ) := by
  sorry
