import Mathlib

theorem fib_prod_cross_shift_nat_int (n : ℕ) : (Nat.fib (n + 1) : ℤ) * Nat.fib (n + 2) - Nat.fib n * Nat.fib (n + 3) = (-1) ^ n := by
  sorry
