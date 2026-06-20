import Mathlib

open Finset in
theorem sum_range_k_sq_mul_choose_eq (n : ℕ) : 4 * ∑ k ∈ Finset.range (n + 1), k ^ 2 * n.choose k = n * (n + 1) * 2 ^ n := by
  sorry
