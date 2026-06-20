import Mathlib

theorem gcd_n2_n4_dvd_two (n : ℕ) : Nat.gcd (n + 2) (n + 4) ∣ 2 := by
  have h1 : Nat.gcd (n + 2) (n + 4) ∣ (n + 2) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 2) (n + 4) ∣ (n + 2) + 2 := by
    have heq : n + 4 = (n + 2) + 2 := by omega
    rw [← heq]
    exact Nat.gcd_dvd_right _ _
  exact (Nat.dvd_add_right h1).mp h2
