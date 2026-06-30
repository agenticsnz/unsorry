import Mathlib

theorem arith_series_sum_coeff_twentythree (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 23) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 23 * (n : ℤ) := by
  sorry
