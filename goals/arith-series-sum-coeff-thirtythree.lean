import Mathlib

theorem arith_series_sum_coeff_thirtythree (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 33) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 33 * (n : ℤ) := by
  sorry
