import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Ring

theorem cube_eq_triangular_sq_diff (n : ℕ) :
    (∑ i ∈ Finset.range n, i) ^ 2 + n ^ 3 = (∑ i ∈ Finset.range (n + 1), i) ^ 2 := by
  rw [Finset.sum_range_succ]
  cases n with
  | zero => simp
  | succ k =>
    have h : (∑ i ∈ Finset.range (k + 1), i) * 2 = (k + 1) * k := by
      rw [Finset.sum_range_id_mul_two, Nat.add_sub_cancel]
    have expand : ((∑ i ∈ Finset.range (k + 1), i) + (k + 1)) ^ 2
        = (∑ i ∈ Finset.range (k + 1), i) ^ 2
          + (k + 1) * ((∑ i ∈ Finset.range (k + 1), i) * 2) + (k + 1) ^ 2 := by ring
    rw [expand, h]; ring
