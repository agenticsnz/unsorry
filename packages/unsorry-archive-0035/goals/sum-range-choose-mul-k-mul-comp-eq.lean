import Mathlib

open Nat Finset
theorem sum_range_choose_mul_k_mul_comp_eq (n : ℕ) : 4 * ∑ k ∈ Finset.range (n + 1), n.choose k * (k * (n - k)) = n * (n - 1) * 2 ^ n := by
  sorry
