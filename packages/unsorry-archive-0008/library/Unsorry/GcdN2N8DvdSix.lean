import Mathlib

theorem gcd_n2_n8_dvd_six (n : ℕ) : Nat.gcd (n + 2) (n + 8) ∣ 6 := by
  have h1 : Nat.gcd (n + 2) (n + 8) ∣ (n + 2) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 2) (n + 8) ∣ (n + 2) + 6 := by
    have heq : n + 8 = (n + 2) + 6 := by omega
    rw [← heq]
    exact Nat.gcd_dvd_right _ _
  exact (Nat.dvd_add_right h1).mp h2
