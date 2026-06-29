import Mathlib

theorem telescoping_sextic_sum_coeff_sixtyseven (n : ℕ) : ∑ k ∈ Finset.range n, (67 * (6 * (k : ℤ) ^ 5 + 15 * (k : ℤ) ^ 4 + 20 * (k : ℤ) ^ 3 + 15 * (k : ℤ) ^ 2 + 6 * (k : ℤ) + 1)) = 67 * (n : ℤ) ^ 6 := by
  sorry
