import Mathlib

theorem arith_series_sum_coeff_one (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 1) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 1 * (n : ℤ) := by
  sorry
