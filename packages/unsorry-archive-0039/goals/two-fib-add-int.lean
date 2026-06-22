import Mathlib

theorem two_fib_add_int (m n : ℤ) : 2 * Int.fib (m + n) = Int.fib m * (Int.fib (n - 1) + Int.fib (n + 1)) + (Int.fib (m - 1) + Int.fib (m + 1)) * Int.fib n := by
  sorry
