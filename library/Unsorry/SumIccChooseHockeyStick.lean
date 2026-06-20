import Unsorry.SumIccChooseHockeyStickS1
import Unsorry.SumIccChooseHockeyStickS2
import Unsorry.SumIccChooseHockeyStickS3

open scoped BigOperators

theorem sum_icc_choose_hockey_stick (n r : ℕ) :
    ∑ k ∈ Finset.Icc r n, k.choose r = (n + 1).choose (r + 1) := by
  induction n with
  | zero =>
      simpa using sum_icc_choose_zero_right r
  | succ n ih =>
      rw [sum_icc_choose_succ_right, ih]
      exact (choose_succ_succ_add n r).symm
