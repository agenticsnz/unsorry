import Mathlib

theorem telescoping_quartic_sum_coeff_forty (n : ℕ) : ∑ k ∈ Finset.range n, (40 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 40 * (n : ℤ) ^ 4 := by
  sorry
