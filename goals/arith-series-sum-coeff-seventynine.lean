import Mathlib

theorem arith_series_sum_coeff_seventynine (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 79) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 79 * (n : ℤ) := by
  sorry
