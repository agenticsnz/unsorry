import Mathlib

theorem telescoping_quartic_sum_coeff_thirteen (n : ℕ) : ∑ k ∈ Finset.range n, (13 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 13 * (n : ℤ) ^ 4 := by
  sorry
