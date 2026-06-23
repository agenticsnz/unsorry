import Mathlib

theorem telescoping_quartic_sum_coeff_fortythree (n : ℕ) : ∑ k ∈ Finset.range n, (43 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 43 * (n : ℤ) ^ 4 := by
  sorry
