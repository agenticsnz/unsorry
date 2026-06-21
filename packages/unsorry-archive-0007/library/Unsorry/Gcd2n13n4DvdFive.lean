import Mathlib

theorem gcd_2n1_3n4_dvd_five (n : ℕ) : Nat.gcd (2 * n + 1) (3 * n + 4) ∣ 5 := by
  have h1 : Nat.gcd (2 * n + 1) (3 * n + 4) ∣ (2 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n + 1) (3 * n + 4) ∣ (3 * n + 4) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (2 * n + 1) (3 * n + 4) ∣ 3 * (2 * n + 1) := h1.mul_left 3
  have h4 : Nat.gcd (2 * n + 1) (3 * n + 4) ∣ 3 * (2 * n + 1) + 5 := by
    have heq : 3 * (2 * n + 1) + 5 = 2 * (3 * n + 4) := by omega
    rw [heq]
    exact h2.mul_left 2
  exact (Nat.dvd_add_right h3).mp h4
