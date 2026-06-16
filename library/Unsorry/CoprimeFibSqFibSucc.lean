import Mathlib

theorem coprime_fib_sq_fib_succ (n : ℕ) : Nat.Coprime (Nat.fib n ^ 2) (Nat.fib (n + 1)) := by
  exact (Nat.fib_coprime_fib_succ n).pow_left 2
