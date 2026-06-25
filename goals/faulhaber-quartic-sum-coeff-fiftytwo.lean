import Mathlib

theorem faulhaber_quartic_sum_coeff_fiftytwo (n : ℕ) : 1560 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 52 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  sorry
