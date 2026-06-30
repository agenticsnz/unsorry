import Mathlib

theorem arith_series_sum_coeff_thirteen (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 13) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 13 * (n : ℤ) := by
  sorry
