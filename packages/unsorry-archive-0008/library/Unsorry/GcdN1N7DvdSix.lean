import Mathlib

theorem gcd_n1_n7_dvd_six (n : ℕ) : Nat.gcd (n + 1) (n + 7) ∣ 6 := by
  have h1 : Nat.gcd (n + 1) (n + 7) ∣ (n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 1) (n + 7) ∣ (n + 1) + 6 := by
    have heq : n + 7 = (n + 1) + 6 := by omega
    rw [← heq]
    exact Nat.gcd_dvd_right _ _
  exact (Nat.dvd_add_right h1).mp h2
