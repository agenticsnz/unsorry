import Mathlib

theorem gcd_n3_2n7_eq_one (n : ℕ) : Nat.gcd (n + 3) (2 * n + 7) = 1 := by
  have h1 : Nat.gcd (n + 3) (2 * n + 7) ∣ (n + 3) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 3) (2 * n + 7) ∣ (2 * n + 7) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (n + 3) (2 * n + 7) ∣ 2 * (n + 3) := h1.mul_left 2
  have h4 : Nat.gcd (n + 3) (2 * n + 7) ∣ 2 * (n + 3) + 1 := by
    have heq : 2 * (n + 3) + 1 = 2 * n + 7 := by omega
    rw [heq]
    exact h2
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h4)
