import Mathlib

theorem telescoping_quintic_sum_coeff_sixtyone (n : ℕ) : ∑ k ∈ Finset.range n, (61 * (5 * (k : ℤ) ^ 4 + 10 * (k : ℤ) ^ 3 + 10 * (k : ℤ) ^ 2 + 5 * (k : ℤ) + 1)) = 61 * (n : ℤ) ^ 5 := by
  sorry
