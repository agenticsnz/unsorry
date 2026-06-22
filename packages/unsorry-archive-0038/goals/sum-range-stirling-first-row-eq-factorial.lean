import Mathlib

open Nat in
theorem sum_range_stirling_first_row_eq_factorial (n : ℕ) :
    ∑ k ∈ Finset.range (n + 1), Nat.stirlingFirst n k = n.factorial := by
  sorry
