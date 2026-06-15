import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

theorem sum_range_pow_five_closed_form (n : ℕ) :
    12 * ∑ i ∈ Finset.range (n + 1), i ^ 5 = n ^ 2 * (n + 1) ^ 2 * (2 * n ^ 2 + 2 * n - 1) := by
  induction n with
  | zero => norm_num
  | succ k ih =>
    have hsub : 2 * (k + 1) ^ 2 + 2 * (k + 1) - 1 = 2 * k ^ 2 + 6 * k + 3 := by
      have h : 2 * (k + 1) ^ 2 + 2 * (k + 1) = 2 * k ^ 2 + 6 * k + 3 + 1 := by ring
      rw [h, Nat.add_sub_cancel]
    rw [Finset.sum_range_succ, Nat.mul_add, ih, hsub]
    cases k with
    | zero => norm_num
    | succ m =>
      have hsub' : 2 * (m + 1) ^ 2 + 2 * (m + 1) - 1 = 2 * m ^ 2 + 6 * m + 3 := by
        have h : 2 * (m + 1) ^ 2 + 2 * (m + 1) = 2 * m ^ 2 + 6 * m + 3 + 1 := by ring
        rw [h, Nat.add_sub_cancel]
      rw [hsub']
      ring
