import Mathlib

theorem telescoping_quartic_sum_coeff_fortynine (n : ℕ) : ∑ k ∈ Finset.range n, (49 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 49 * (n : ℤ) ^ 4 := by
  sorry
