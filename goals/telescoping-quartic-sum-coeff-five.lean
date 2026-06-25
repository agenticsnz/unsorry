import Mathlib

theorem telescoping_quartic_sum_coeff_five (n : ℕ) : ∑ k ∈ Finset.range n, (5 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 5 * (n : ℤ) ^ 4 := by
  sorry
