import Mathlib

theorem arith_series_sum_coeff_sixtythree (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 63) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 63 * (n : ℤ) := by
  sorry
