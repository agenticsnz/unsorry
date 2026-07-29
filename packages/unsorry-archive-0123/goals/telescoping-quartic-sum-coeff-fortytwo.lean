import Mathlib

theorem telescoping_quartic_sum_coeff_fortytwo (n : ℕ) : ∑ k ∈ Finset.range n, (42 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 42 * (n : ℤ) ^ 4 := by
  sorry
