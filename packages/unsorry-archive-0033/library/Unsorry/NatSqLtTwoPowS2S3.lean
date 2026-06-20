import Mathlib

theorem two_mul_two_pow_eq_two_pow_succ_nat (n : Nat) :
    2 * 2 ^ n = 2 ^ (n + 1) := by
  rw [Nat.pow_succ]
  exact Nat.mul_comm 2 (2 ^ n)
