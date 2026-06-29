import Mathlib

theorem arith_series_sum_coeff_sixtyseven (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 67) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 67 * (n : ℤ) := by
  sorry
