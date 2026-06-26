import Mathlib

theorem arith_series_sum_coeff_forty (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 40) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 40 * (n : ℤ) := by
  sorry
