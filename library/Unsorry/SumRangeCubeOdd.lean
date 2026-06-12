import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

theorem sum_range_cube_odd (n : ℕ) :
    ∑ i ∈ Finset.range n, (2 * i + 1) ^ 3 = n ^ 2 * (2 * n ^ 2 - 1) := by
  induction n with
  | zero => norm_num
  | succ k ih =>
    have hsub : 2 * (k + 1) ^ 2 - 1 = 2 * k ^ 2 + 4 * k + 1 := by
      have h : 2 * (k + 1) ^ 2 = 2 * k ^ 2 + 4 * k + 1 + 1 := by ring
      rw [h, Nat.add_sub_cancel]
    rw [Finset.sum_range_succ, ih, hsub]
    cases k with
    | zero => norm_num
    | succ m =>
      have hsub' : 2 * (m + 1) ^ 2 - 1 = 2 * m ^ 2 + 4 * m + 1 := by
        have h : 2 * (m + 1) ^ 2 = 2 * m ^ 2 + 4 * m + 1 + 1 := by ring
        rw [h, Nat.add_sub_cancel]
      rw [hsub']
      ring
