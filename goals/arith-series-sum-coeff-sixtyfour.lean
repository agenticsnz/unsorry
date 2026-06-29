import Mathlib

theorem arith_series_sum_coeff_sixtyfour (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 64) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 64 * (n : ℤ) := by
  sorry
