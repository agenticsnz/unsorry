import Mathlib

theorem arith_series_sum_coeff_fortyeight (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 48) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 48 * (n : ℤ) := by
  sorry
