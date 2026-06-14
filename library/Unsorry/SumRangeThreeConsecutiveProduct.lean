import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.Ring

theorem sum_range_mul_succ_mul_succ_succ_aux (m : ℕ) :
    4 * ∑ i ∈ Finset.range (m + 1), i * (i + 1) * (i + 2)
      = m * (m + 1) * (m + 2) * (m + 3) := by
  induction m with
  | zero => simp
  | succ j ih =>
    rw [Finset.sum_range_succ, mul_add, ih]
    ring

theorem sum_range_mul_succ_mul_succ_succ (n : ℕ) :
    4 * ∑ i ∈ Finset.range n, i * (i + 1) * (i + 2)
      = (n - 1) * n * (n + 1) * (n + 2) := by
  cases n with
  | zero => simp
  | succ m => exact sum_range_mul_succ_mul_succ_succ_aux m
