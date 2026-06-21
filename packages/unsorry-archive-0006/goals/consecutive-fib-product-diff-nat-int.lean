import Mathlib

theorem consecutive_fib_product_diff_nat_int (n : ℕ) : (Nat.fib n : ℤ) * Nat.fib (n + 3) - Nat.fib (n + 1) * Nat.fib (n + 2) = (-1) ^ (n + 1) := by
  sorry
