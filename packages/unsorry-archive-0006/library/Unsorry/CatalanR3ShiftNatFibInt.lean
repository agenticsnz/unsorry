import Mathlib

theorem catalan_r3_shift_nat_fib_int (n : ℕ) : (Nat.fib (n + 3) : ℤ) ^ 2 - Nat.fib n * Nat.fib (n + 6) = 4 * (-1) ^ n := by
  have h := Int.fib_add_sq_sub_fib_mul_fib_add_two_mul (n : ℤ) 3
  have e3 : Int.fib 3 = 2 := by decide
  rw [Int.natAbs_natCast, e3] at h
  have c1 : Int.fib ((n : ℤ) + 3) = (Nat.fib (n + 3) : ℤ) := by
    rw [show ((n : ℤ) + 3) = ((n + 3 : ℕ) : ℤ) by push_cast; ring, Int.fib_natCast]
  have c2 : Int.fib ((n : ℤ)) = (Nat.fib n : ℤ) := Int.fib_natCast n
  have c3 : Int.fib ((n : ℤ) + 2 * 3) = (Nat.fib (n + 6) : ℤ) := by
    rw [show ((n : ℤ) + 2 * 3) = ((n + 6 : ℕ) : ℤ) by push_cast; ring, Int.fib_natCast]
  rw [c1, c2, c3] at h
  rw [h]
  ring