import Mathlib

open Nat Finset
theorem sum_range_choose_mul_choose_three_eq (n : ℕ) : 8 * ∑ k ∈ Finset.range (n + 1), n.choose k * k.choose 3 = n.choose 3 * 2 ^ n := by
  sorry
