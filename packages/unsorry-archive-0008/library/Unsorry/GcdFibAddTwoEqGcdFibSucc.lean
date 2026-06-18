import Mathlib

theorem gcd_fib_add_two_eq_gcd_fib_succ (n : ℕ) : Nat.gcd (Nat.fib n) (Nat.fib (n + 2)) = Nat.gcd (Nat.fib n) (Nat.fib (n + 1)) := by
  rw [Nat.fib_add_two, Nat.add_comm (Nat.fib n) (Nat.fib (n + 1)), Nat.gcd_add_self_right]
