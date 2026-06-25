import Mathlib

theorem telescoping_quartic_sum_coeff_thirtyseven (n : ℕ) : ∑ k ∈ Finset.range n, (37 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 37 * (n : ℤ) ^ 4 := by
  sorry
