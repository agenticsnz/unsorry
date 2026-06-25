import Mathlib

theorem arith_series_sum_coeff_fiftythree (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 53) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 53 * (n : ℤ) := by
  sorry
