import Mathlib

theorem sum_range_multichoose_two_eq_choose_succ_two (m : ℕ) : ∑ j ∈ Finset.range (m + 1), Nat.multichoose 2 j = Nat.choose (m + 2) 2 := by
  induction m with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, ih]
    have hm : Nat.multichoose 2 (k + 1) = k + 2 := by
      simp
    rw [hm]
    have hrec : Nat.choose (k + 1 + 2) 2 = Nat.choose (k + 2) 2 + Nat.choose (k + 2) 1 := by
      rw [show k + 1 + 2 = (k + 2) + 1 from rfl, Nat.choose_succ_succ]
      ring
    rw [hrec, Nat.choose_one_right]