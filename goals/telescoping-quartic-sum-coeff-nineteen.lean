import Mathlib

theorem telescoping_quartic_sum_coeff_nineteen (n : ℕ) : ∑ k ∈ Finset.range n, (19 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 19 * (n : ℤ) ^ 4 := by
  sorry
