import Mathlib

theorem gcd_n2p1_n2p3_dvd_two (n : ℕ) : Nat.gcd (n^2 + 1) (n^2 + 3) ∣ 2 := by
  have h1 : Nat.gcd (n^2 + 1) (n^2 + 3) ∣ (n^2 + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n^2 + 1) (n^2 + 3) ∣ (n^2 + 3) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (n^2 + 1) (n^2 + 3) ∣ (n^2 + 1) + 2 := by
    have heq : (n^2 + 1) + 2 = n^2 + 3 := by omega
    rw [heq]; exact h2
  exact (Nat.dvd_add_right h1).mp h3
