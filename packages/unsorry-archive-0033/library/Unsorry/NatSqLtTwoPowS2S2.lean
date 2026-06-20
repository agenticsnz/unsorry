import Mathlib.Data.Nat.Basic

theorem two_mul_square_lt_two_mul_pow_of_square_lt {n : Nat} (h : n ^ 2 < 2 ^ n) :
    2 * n ^ 2 < 2 * 2 ^ n := by
  exact Nat.mul_lt_mul_of_pos_left h (by decide)
