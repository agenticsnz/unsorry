import Mathlib

theorem telescoping_sextic_sum_coeff_seventyone (n : ℕ) : ∑ k ∈ Finset.range n, (71 * (6 * (k : ℤ) ^ 5 + 15 * (k : ℤ) ^ 4 + 20 * (k : ℤ) ^ 3 + 15 * (k : ℤ) ^ 2 + 6 * (k : ℤ) + 1)) = 71 * (n : ℤ) ^ 6 := by
  sorry
