import Mathlib

theorem telescoping_quartic_sum_coeff_fortyfive (n : ℕ) : ∑ k ∈ Finset.range n, (45 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 45 * (n : ℤ) ^ 4 := by
  sorry
