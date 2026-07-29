import Mathlib

theorem telescoping_quartic_sum_coeff_sixtyfive (n : ℕ) : ∑ k ∈ Finset.range n, (65 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 65 * (n : ℤ) ^ 4 := by
  sorry
