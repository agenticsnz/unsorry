import Mathlib

theorem telescoping_cube_sum_coeff_three (n : ℕ) : ∑ k ∈ Finset.range n, (3 * (3 * (k : ℤ) ^ 2 + 3 * (k : ℤ) + 1)) = 3 * (n : ℤ) ^ 3 := by
  sorry
