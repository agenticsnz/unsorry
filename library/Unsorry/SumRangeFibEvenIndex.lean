import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Nat.Fib.Basic

theorem sum_range_fib_two_mul (n : ℕ) :
    ∑ i ∈ Finset.range n, Nat.fib (2 * (i + 1)) = Nat.fib (2 * n + 1) - 1 := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, ih]
    have key : Nat.fib (2 * (k + 1) + 1)
        = Nat.fib (2 * k + 1) + Nat.fib (2 * (k + 1)) := by
      have e1 : 2 * (k + 1) + 1 = (2 * k + 1) + 2 := by ring
      have e2 : (2 * k + 1) + 1 = 2 * (k + 1) := by ring
      rw [e1, Nat.fib_add_two, e2]
    have hpos : 0 < Nat.fib (2 * k + 1) := Nat.fib_pos.mpr (by omega)
    omega
