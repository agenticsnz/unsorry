import Mathlib

theorem sum_range_multichoose_two_eq_choose_succ_two (m : ℕ) : ∑ j ∈ Finset.range (m + 1), Nat.multichoose 2 j = Nat.choose (m + 2) 2 := by
  sorry
