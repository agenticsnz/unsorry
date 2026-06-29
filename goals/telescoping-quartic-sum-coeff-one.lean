import Mathlib

theorem telescoping_quartic_sum_coeff_one (n : ℕ) : ∑ k ∈ Finset.range n, (1 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 1 * (n : ℤ) ^ 4 := by
  sorry
