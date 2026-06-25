import Mathlib

theorem telescoping_quartic_sum_coeff_thirtysix (n : ℕ) : ∑ k ∈ Finset.range n, (36 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 36 * (n : ℤ) ^ 4 := by
  sorry
