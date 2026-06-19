import Mathlib

theorem gcd_n2_n6_dvd_four (n : ℕ) : Nat.gcd (n + 2) (n + 6) ∣ 4 := by
  have h1 : Nat.gcd (n + 2) (n + 6) ∣ (n + 2) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 2) (n + 6) ∣ (n + 2) + 4 := by
    have heq : n + 6 = (n + 2) + 4 := by omega
    rw [← heq]
    exact Nat.gcd_dvd_right _ _
  exact (Nat.dvd_add_right h1).mp h2
