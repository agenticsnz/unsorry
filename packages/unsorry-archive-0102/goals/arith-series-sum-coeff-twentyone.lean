import Mathlib

theorem arith_series_sum_coeff_twentyone (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 21) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 21 * (n : ℤ) := by
  sorry
