import Mathlib

theorem telescoping_quartic_sum_coeff_sixtyfour (n : ℕ) : ∑ k ∈ Finset.range n, (64 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 64 * (n : ℤ) ^ 4 := by
  sorry
