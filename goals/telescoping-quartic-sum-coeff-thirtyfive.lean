import Mathlib

theorem telescoping_quartic_sum_coeff_thirtyfive (n : ℕ) : ∑ k ∈ Finset.range n, (35 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 35 * (n : ℤ) ^ 4 := by
  sorry
