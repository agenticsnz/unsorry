import Mathlib

theorem telescoping_quartic_sum_coeff_nine (n : ℕ) : ∑ k ∈ Finset.range n, (9 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 9 * (n : ℤ) ^ 4 := by
  sorry
