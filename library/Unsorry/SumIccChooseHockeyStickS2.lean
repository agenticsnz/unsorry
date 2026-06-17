import Mathlib

theorem sum_icc_choose_succ_right (n r : ℕ) : ∑ k ∈ Finset.Icc r (n + 1), k.choose r = (∑ k ∈ Finset.Icc r n, k.choose r) + (n + 1).choose r := by
  rcases le_or_gt r (n + 1) with h | h
  · exact Finset.sum_Icc_succ_top h _
  · rw [Finset.Icc_eq_empty (by omega), Finset.Icc_eq_empty (by omega)]
    simp [Nat.choose_eq_zero_of_lt h]