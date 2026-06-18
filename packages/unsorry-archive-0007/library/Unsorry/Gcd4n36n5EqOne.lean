import Mathlib

theorem gcd_4n3_6n5_eq_one (n : ℕ) : Nat.gcd (4 * n + 3) (6 * n + 5) = 1 := by
  have h1 : Nat.gcd (4 * n + 3) (6 * n + 5) ∣ (4 * n + 3) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (4 * n + 3) (6 * n + 5) ∣ (6 * n + 5) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (4 * n + 3) (6 * n + 5) ∣ 3 * (4 * n + 3) := h1.mul_left 3
  have h4 : Nat.gcd (4 * n + 3) (6 * n + 5) ∣ 3 * (4 * n + 3) + 1 := by
    have heq : 3 * (4 * n + 3) + 1 = 2 * (6 * n + 5) := by omega
    rw [heq]
    exact h2.mul_left 2
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h4)
