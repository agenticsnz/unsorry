import Mathlib

theorem gcd_factorial_succ_eq_factorial (n : ℕ) : Nat.gcd (Nat.factorial n) (Nat.factorial (n + 1)) = Nat.factorial n := by
  exact Nat.gcd_eq_left (Nat.factorial_dvd_factorial (Nat.le_succ n))
