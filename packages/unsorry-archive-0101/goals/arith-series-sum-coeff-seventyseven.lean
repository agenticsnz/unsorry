import Mathlib

theorem arith_series_sum_coeff_seventyseven (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 77) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 77 * (n : ℤ) := by
  sorry
