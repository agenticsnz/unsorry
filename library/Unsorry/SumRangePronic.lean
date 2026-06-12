import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.Ring

theorem sum_range_pronic (n : ℕ) :
    3 * ∑ i ∈ Finset.range (n + 1), i * (i + 1) = n * (n + 1) * (n + 2) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    ring
