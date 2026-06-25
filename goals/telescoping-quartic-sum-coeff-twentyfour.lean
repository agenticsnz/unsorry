import Mathlib

theorem telescoping_quartic_sum_coeff_twentyfour (n : ℕ) : ∑ k ∈ Finset.range n, (24 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 24 * (n : ℤ) ^ 4 := by
  sorry
