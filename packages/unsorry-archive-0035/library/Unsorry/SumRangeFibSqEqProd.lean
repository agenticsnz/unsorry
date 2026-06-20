import Mathlib

theorem sum_range_fib_sq_eq_prod (n : ℕ) : ∑ i ∈ Finset.range (n + 1), Nat.fib i ^ 2 = Nat.fib n * Nat.fib (n + 1) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, ih, Nat.fib_add_two]
    ring
