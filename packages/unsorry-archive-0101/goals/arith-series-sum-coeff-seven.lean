import Mathlib

theorem arith_series_sum_coeff_seven (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 7) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 7 * (n : ℤ) := by
  sorry
