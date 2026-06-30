import Mathlib

theorem arith_series_sum_coeff_two (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 2) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 2 * (n : ℤ) := by
  sorry
