import Mathlib

open Finset in
theorem alt_sum_range_choose_sq_eq_zero_odd (n : ℕ) (hn : Odd n) : ∑ k ∈ Finset.range (n + 1), ((-1 : ℤ)) ^ k * (n.choose k : ℤ) ^ 2 = 0 := by
  sorry
