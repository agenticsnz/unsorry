import Mathlib

theorem telescoping_quartic_sum_coeff_fortyfour (n : ℕ) : ∑ k ∈ Finset.range n, (44 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 44 * (n : ℤ) ^ 4 := by
  sorry
