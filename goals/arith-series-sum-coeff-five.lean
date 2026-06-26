import Mathlib

theorem arith_series_sum_coeff_five (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 5) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 5 * (n : ℤ) := by
  sorry
