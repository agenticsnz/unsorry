import Mathlib

theorem telescoping_quintic_sum_coeff_nineteen (n : ℕ) : ∑ k ∈ Finset.range n, (19 * (5 * (k : ℤ) ^ 4 + 10 * (k : ℤ) ^ 3 + 10 * (k : ℤ) ^ 2 + 5 * (k : ℤ) + 1)) = 19 * (n : ℤ) ^ 5 := by
  sorry
