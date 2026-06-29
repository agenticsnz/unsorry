import Mathlib

theorem telescoping_sextic_sum_coeff_fortytwo (n : ℕ) : ∑ k ∈ Finset.range n, (42 * (6 * (k : ℤ) ^ 5 + 15 * (k : ℤ) ^ 4 + 20 * (k : ℤ) ^ 3 + 15 * (k : ℤ) ^ 2 + 6 * (k : ℤ) + 1)) = 42 * (n : ℤ) ^ 6 := by
  sorry
