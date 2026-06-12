import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

theorem sum_range_pentagonal_closed_form (n : ℕ) :
    2 * (∑ k ∈ Finset.range (n + 1), (3 * k ^ 2 - k) / 2) = n ^ 2 * (n + 1) := by
  induction n with
  | zero => norm_num
  | succ j ih =>
    have hsub : 3 * (j + 1) ^ 2 - (j + 1) = 3 * j ^ 2 + 5 * j + 2 := by
      have h : 3 * (j + 1) ^ 2 = 3 * j ^ 2 + 5 * j + 2 + (j + 1) := by ring
      rw [h, Nat.add_sub_cancel]
    have hdvd : 2 ∣ 3 * j ^ 2 + 5 * j + 2 := by
      rcases Nat.even_or_odd j with ⟨t, rfl⟩ | ⟨t, rfl⟩
      · exact ⟨6 * t ^ 2 + 5 * t + 1, by ring⟩
      · exact ⟨6 * t ^ 2 + 11 * t + 5, by ring⟩
    rw [Finset.sum_range_succ, Nat.mul_add, ih, hsub, Nat.mul_div_cancel' hdvd]
    ring
