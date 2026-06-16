import Mathlib

theorem gcd_3n2_5n4_dvd_two (n : ℕ) : Nat.gcd (3 * n + 2) (5 * n + 4) ∣ 2 := by
  have h1 : Nat.gcd (3 * n + 2) (5 * n + 4) ∣ (3 * n + 2) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (3 * n + 2) (5 * n + 4) ∣ (5 * n + 4) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (3 * n + 2) (5 * n + 4) ∣ 5 * (3 * n + 2) := h1.mul_left 5
  have h4 : Nat.gcd (3 * n + 2) (5 * n + 4) ∣ 5 * (3 * n + 2) + 2 := by
    have heq : 5 * (3 * n + 2) + 2 = 3 * (5 * n + 4) := by omega
    rw [heq]; exact h2.mul_left 3
  exact (Nat.dvd_add_right h3).mp h4
