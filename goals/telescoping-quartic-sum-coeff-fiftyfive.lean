import Mathlib

theorem telescoping_quartic_sum_coeff_fiftyfive (n : ℕ) : ∑ k ∈ Finset.range n, (55 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 55 * (n : ℤ) ^ 4 := by
  sorry
