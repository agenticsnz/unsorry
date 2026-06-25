import Mathlib

theorem arith_series_sum_coeff_fortythree (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 43) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 43 * (n : ℤ) := by
  sorry
