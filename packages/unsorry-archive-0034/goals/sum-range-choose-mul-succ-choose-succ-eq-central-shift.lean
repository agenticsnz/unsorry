import Mathlib

open Finset in
theorem sum_range_choose_mul_succ_choose_succ_eq_central_shift (n : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose k * (n + 1).choose (k + 1) = (2 * n + 1).choose (n + 1) := by
  sorry
