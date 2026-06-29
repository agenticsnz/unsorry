import Mathlib

theorem telescoping_quartic_sum_coeff_sixteen (n : ℕ) : ∑ k ∈ Finset.range n, (16 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 16 * (n : ℤ) ^ 4 := by
  sorry
