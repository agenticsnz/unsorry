import Mathlib

theorem gcd_3n1_5n2_eq_one (n : ℕ) : Nat.gcd (3 * n + 1) (5 * n + 2) = 1 := by
  have h1 : Nat.gcd (3 * n + 1) (5 * n + 2) ∣ (3 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (3 * n + 1) (5 * n + 2) ∣ (5 * n + 2) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (3 * n + 1) (5 * n + 2) ∣ 5 * (3 * n + 1) := h1.mul_left 5
  have h4 : Nat.gcd (3 * n + 1) (5 * n + 2) ∣ 5 * (3 * n + 1) + 1 := by
    have heq : 5 * (3 * n + 1) + 1 = 3 * (5 * n + 2) := by omega
    rw [heq]
    exact h2.mul_left 3
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h4)
