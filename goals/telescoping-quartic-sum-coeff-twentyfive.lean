import Mathlib

theorem telescoping_quartic_sum_coeff_twentyfive (n : ℕ) : ∑ k ∈ Finset.range n, (25 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 25 * (n : ℤ) ^ 4 := by
  sorry
