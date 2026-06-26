import Mathlib

theorem arith_series_sum_coeff_sixtyfive (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 65) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 65 * (n : ℤ) := by
  sorry
