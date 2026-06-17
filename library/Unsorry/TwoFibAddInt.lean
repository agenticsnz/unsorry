import Mathlib

theorem two_fib_add_int (m n : ℤ) : 2 * Int.fib (m + n) = Int.fib m * (Int.fib (n - 1) + Int.fib (n + 1)) + (Int.fib (m - 1) + Int.fib (m + 1)) * Int.fib n := by
  have h1 := Int.fib_add m n
  have h2 := Int.fib_add n m
  rw [add_comm n m] at h2
  linear_combination h1 + h2
