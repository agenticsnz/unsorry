import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Choose.Basic

theorem sum_range_id_eq_choose_two (n : ℕ) :
    ∑ i ∈ Finset.range n, i = Nat.choose n 2 := by
  rw [Finset.sum_range_id, Nat.choose_two_right]
