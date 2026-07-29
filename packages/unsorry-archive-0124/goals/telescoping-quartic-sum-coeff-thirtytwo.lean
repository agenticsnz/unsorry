import Mathlib

theorem telescoping_quartic_sum_coeff_thirtytwo (n : ℕ) : ∑ k ∈ Finset.range n, (32 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 32 * (n : ℤ) ^ 4 := by
  sorry
