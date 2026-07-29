import Mathlib

theorem telescoping_quartic_sum_coeff_fiftytwo (n : ℕ) : ∑ k ∈ Finset.range n, (52 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 52 * (n : ℤ) ^ 4 := by
  sorry
