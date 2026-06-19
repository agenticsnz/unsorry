import Mathlib.Data.Nat.GCD.Basic

/-- The numbers `2 * n + 1` and `3 * n + 2` are coprime for every natural `n`.

The key identity is `2 * (3 * n + 2) = 3 * (2 * n + 1) + 1`, so any common
divisor of the two numbers divides `1`. -/
theorem coprime_2n1_3n2 (n : ℕ) : Nat.Coprime (2 * n + 1) (3 * n + 2) := by
  show Nat.gcd (2 * n + 1) (3 * n + 2) = 1
  have h1 : Nat.gcd (2 * n + 1) (3 * n + 2) ∣ 2 * n + 1 := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n + 1) (3 * n + 2) ∣ 3 * n + 2 := Nat.gcd_dvd_right _ _
  have h3 := h1.mul_left 3
  have h4 := h2.mul_left 2
  have h5 : 2 * (3 * n + 2) = 3 * (2 * n + 1) + 1 := by omega
  rw [h5] at h4
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h4)
