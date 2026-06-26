import Mathlib

open Finset
theorem sum_four_consecutive_eq_hyper_tetrahedral (n : ℕ) : 5 * ∑ k ∈ Finset.range n, (k + 1) * (k + 2) * (k + 3) * (k + 4) = n * (n + 1) * (n + 2) * (n + 3) * (n + 4) := by
  sorry
