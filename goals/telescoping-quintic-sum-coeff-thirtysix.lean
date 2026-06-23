import Mathlib

theorem telescoping_quintic_sum_coeff_thirtysix (n : ℕ) : ∑ k ∈ Finset.range n, (36 * (5 * (k : ℤ) ^ 4 + 10 * (k : ℤ) ^ 3 + 10 * (k : ℤ) ^ 2 + 5 * (k : ℤ) + 1)) = 36 * (n : ℤ) ^ 5 := by
  sorry
