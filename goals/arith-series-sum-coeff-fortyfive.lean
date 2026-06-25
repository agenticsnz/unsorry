import Mathlib

theorem arith_series_sum_coeff_fortyfive (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 45) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 45 * (n : ℤ) := by
  sorry
