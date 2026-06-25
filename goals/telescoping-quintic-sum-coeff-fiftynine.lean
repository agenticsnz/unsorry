import Mathlib

theorem telescoping_quintic_sum_coeff_fiftynine (n : ℕ) : ∑ k ∈ Finset.range n, (59 * (5 * (k : ℤ) ^ 4 + 10 * (k : ℤ) ^ 3 + 10 * (k : ℤ) ^ 2 + 5 * (k : ℤ) + 1)) = 59 * (n : ℤ) ^ 5 := by
  sorry
