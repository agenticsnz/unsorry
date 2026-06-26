import Mathlib

theorem telescoping_quartic_sum_coeff_fortyseven (n : ℕ) : ∑ k ∈ Finset.range n, (47 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 47 * (n : ℤ) ^ 4 := by
  sorry
