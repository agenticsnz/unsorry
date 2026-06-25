import Mathlib

theorem telescoping_quintic_sum_coeff_seventyseven (n : ℕ) : ∑ k ∈ Finset.range n, (77 * (5 * (k : ℤ) ^ 4 + 10 * (k : ℤ) ^ 3 + 10 * (k : ℤ) ^ 2 + 5 * (k : ℤ) + 1)) = 77 * (n : ℤ) ^ 5 := by
  sorry
