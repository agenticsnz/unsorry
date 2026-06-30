import Mathlib

theorem arith_series_sum_coeff_fortysix (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 46) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 46 * (n : ℤ) := by
  sorry
