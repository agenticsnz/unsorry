import Mathlib

theorem three_mul_fib_eq_fib_add_two_add_fib_sub_two (n : ℕ) : 3 * Nat.fib (n + 2) = Nat.fib (n + 4) + Nat.fib n := by
  have h1 : Nat.fib (n + 4) = Nat.fib (n + 3) + Nat.fib (n + 2) := by
    rw [show n + 4 = (n + 2) + 2 from rfl, Nat.fib_add_two]
    ring_nf
  have h2 : Nat.fib (n + 3) = Nat.fib (n + 2) + Nat.fib (n + 1) := by
    rw [show n + 3 = (n + 1) + 2 from rfl, Nat.fib_add_two]
    ring_nf
  have h3 : Nat.fib (n + 2) = Nat.fib n + Nat.fib (n + 1) := Nat.fib_add_two
  omega