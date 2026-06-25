import Mathlib

theorem arith_series_sum_coeff_fiftynine (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 59) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 59 * (n : ℤ) := by
  sorry
