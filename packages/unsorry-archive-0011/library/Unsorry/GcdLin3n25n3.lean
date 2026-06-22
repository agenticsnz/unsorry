import Mathlib.Data.Nat.GCD.Basic

/-!
# Coprimality of `3 * n + 2` and `5 * n + 3`

For every natural number `n`, the linear forms `3 * n + 2` and `5 * n + 3` are
coprime.  The key identity is `5 * (3 * n + 2) - 3 * (5 * n + 3) = 1`, so any
common divisor must divide `1`.
-/

theorem gcd_lin_3n2_5n3 (n : ℕ) : Nat.gcd (3 * n + 2) (5 * n + 3) = 1 := by
  have h1 : Nat.gcd (3 * n + 2) (5 * n + 3) ∣ (3 * n + 2) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (3 * n + 2) (5 * n + 3) ∣ (5 * n + 3) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (3 * n + 2) (5 * n + 3) ∣ 1 := by
    have hd := Nat.dvd_sub (h1.mul_left 5) (h2.mul_left 3)
    have e : 5 * (3 * n + 2) - 3 * (5 * n + 3) = 1 := by omega
    rwa [e] at hd
  exact Nat.dvd_one.mp h3
