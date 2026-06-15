import Mathlib

theorem gcd_n1_n4_dvd_three (n : ℕ) : Nat.gcd (n + 1) (n + 4) ∣ 3 := by
  have h1 : Nat.gcd (n + 1) (n + 4) ∣ (n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 1) (n + 4) ∣ (n + 4) := Nat.gcd_dvd_right _ _
  have h3 : n + 4 = (n + 1) + 3 := by omega
  rw [h3] at h2
  exact (Nat.dvd_add_right h1).mp h2
