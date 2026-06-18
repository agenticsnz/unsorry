import Mathlib

theorem fib_two_mul_eq_fib_mul_two_mul_fib_succ_sub_fib (n : ℕ) : Nat.fib (2 * n) + Nat.fib n ^ 2 = Nat.fib n * (2 * Nat.fib (n + 1)) := by
  have h : Nat.fib n ≤ 2 * Nat.fib (n + 1) := by
    have := Nat.fib_le_fib_succ (n := n)
    nlinarith [Nat.fib_le_fib_succ (n := n)]
  have h2 : Nat.fib n * Nat.fib n ≤ Nat.fib n * (2 * Nat.fib (n + 1)) :=
    Nat.mul_le_mul_left _ h
  rw [Nat.fib_two_mul, Nat.mul_sub, pow_two]
  omega