import Mathlib

theorem sum_range_fib_sq_eq_fib_mul_fib_succ (n : ℕ) : Finset.sum (Finset.range n) (fun i => Nat.fib (i + 1) ^ 2) = Nat.fib n * Nat.fib (n + 1) := by
  sorry
