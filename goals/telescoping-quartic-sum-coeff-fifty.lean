import Mathlib

theorem telescoping_quartic_sum_coeff_fifty (n : ℕ) : ∑ k ∈ Finset.range n, (50 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 50 * (n : ℤ) ^ 4 := by
  sorry
