import Mathlib.Data.Int.Fib.Basic

theorem fib_two_mul_sq_diff_int (n : ℤ) :
    Int.fib (2 * n) = Int.fib (n + 1) ^ 2 - Int.fib (n - 1) ^ 2 := by
  rw [Int.fib_two_mul]
  have h : Int.fib (n + 1) = Int.fib (n - 1) + Int.fib n := by
    convert Int.fib_add_two (n - 1) using 2 <;> ring
  rw [h]
  ring
