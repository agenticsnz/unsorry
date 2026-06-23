import Mathlib

theorem telescoping_quartic_sum_coeff_eight (n : ℕ) : ∑ k ∈ Finset.range n, (8 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 8 * (n : ℤ) ^ 4 := by
  sorry
