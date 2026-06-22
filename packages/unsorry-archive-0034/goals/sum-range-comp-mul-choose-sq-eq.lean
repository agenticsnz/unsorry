import Mathlib

open Finset
theorem sum_range_comp_mul_choose_sq_eq (n : ℕ) : ∑ k ∈ Finset.range (n + 2), ((n : ℤ) + 1 - k) * (((n + 1).choose k : ℕ) : ℤ) ^ 2 = ((n : ℤ) + 1) * ((2 * n + 2).choose (n + 1) : ℕ) - ((n : ℤ) + 1) * ((2 * n + 1).choose n : ℕ) := by
  sorry
