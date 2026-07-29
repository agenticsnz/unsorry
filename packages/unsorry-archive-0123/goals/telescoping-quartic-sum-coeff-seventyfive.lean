import Mathlib

theorem telescoping_quartic_sum_coeff_seventyfive (n : ℕ) : ∑ k ∈ Finset.range n, (75 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 75 * (n : ℤ) ^ 4 := by
  sorry
