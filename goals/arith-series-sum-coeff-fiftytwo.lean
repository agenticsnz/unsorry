import Mathlib

theorem arith_series_sum_coeff_fiftytwo (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 52) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 52 * (n : ℤ) := by
  sorry
