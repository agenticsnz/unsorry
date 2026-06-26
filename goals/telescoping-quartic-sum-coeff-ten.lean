import Mathlib

theorem telescoping_quartic_sum_coeff_ten (n : ℕ) : ∑ k ∈ Finset.range n, (10 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 10 * (n : ℤ) ^ 4 := by
  sorry
