import Mathlib

theorem gcd_2pow_3pow_eq_one (n : ℕ) : Nat.gcd (2 ^ n) (3 ^ n) = 1 := by
  have h : Nat.Coprime 2 3 := by decide
  exact h.pow n n
