import Mathlib

theorem arith_series_sum_coeff_seventysix (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 76) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 76 * (n : ℤ) := by
  sorry
