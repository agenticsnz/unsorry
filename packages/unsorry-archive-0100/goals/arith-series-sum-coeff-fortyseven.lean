import Mathlib

theorem arith_series_sum_coeff_fortyseven (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 47) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 47 * (n : ℤ) := by
  sorry
