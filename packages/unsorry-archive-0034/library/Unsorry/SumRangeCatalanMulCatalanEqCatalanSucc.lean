import Mathlib

open Finset
theorem sum_range_catalan_mul_catalan_eq_catalan_succ (n : ℕ) : ∑ i ∈ Finset.range (n + 1), catalan i * catalan (n - i) = catalan (n + 1) := by
  rw [catalan_succ, Finset.sum_range]
