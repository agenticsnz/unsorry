import Mathlib

theorem telescoping_sextic_sum_coeff_fortynine (n : ℕ) : ∑ k ∈ Finset.range n, (49 * (6 * (k : ℤ) ^ 5 + 15 * (k : ℤ) ^ 4 + 20 * (k : ℤ) ^ 3 + 15 * (k : ℤ) ^ 2 + 6 * (k : ℤ) + 1)) = 49 * (n : ℤ) ^ 6 := by
  sorry
