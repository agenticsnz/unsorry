import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.Ring

theorem sum_range_cube_even (n : ℕ) :
    ∑ i ∈ Finset.range n, (2 * i) ^ 3 = 2 * n ^ 2 * (n - 1) ^ 2 := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, ih]
    cases k with
    | zero => decide
    | succ j =>
      simp only [Nat.add_sub_cancel]
      ring
