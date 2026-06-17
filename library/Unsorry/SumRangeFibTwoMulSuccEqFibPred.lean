import Mathlib

theorem sum_range_fib_two_mul_succ_eq_fib_pred (n : ℕ) : Finset.sum (Finset.range n) (fun i => Nat.fib (2 * i + 2)) = Nat.fib (2 * n + 1) - 1 := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : 1 ≤ Nat.fib (2 * k + 1) := Nat.fib_pos.mpr (by omega)
    have h2 : Nat.fib (2 * (k + 1) + 1) = Nat.fib (2 * k + 1) + Nat.fib (2 * k + 2) := by
      have : 2 * (k + 1) + 1 = (2 * k + 1) + 2 := by ring
      rw [this, Nat.fib_add_two]
    omega