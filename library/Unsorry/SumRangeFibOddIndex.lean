import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Nat.Fib.Basic

theorem sum_range_fib_two_mul_add_one (n : ℕ) :
    ∑ i ∈ Finset.range n, Nat.fib (2 * i + 1) = Nat.fib (2 * n) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, ih, show 2 * (k + 1) = 2 * k + 2 from by ring,
      Nat.fib_add_two]
