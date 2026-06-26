import Mathlib

theorem gcd_twon_n5_dvd_ten (n : ℕ) : Nat.gcd (2 * n) (n + 5) ∣ 10 := by
  have h1 : Nat.gcd (2 * n) (n + 5) ∣ (2 * n) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n) (n + 5) ∣ (n + 5) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (2 * n) (n + 5) ∣ 2 * n + 10 := by
    have heq : 2 * n + 10 = 2 * (n + 5) := by ring
    rw [heq]; exact h2.mul_left 2
  exact (Nat.dvd_add_right h1).mp h3
