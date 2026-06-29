import Mathlib

open Finset
theorem sum_range_choose_mul_succ_choose_eq (n : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose k * (n + 1).choose k = (2 * n + 1).choose n := by
  sorry
