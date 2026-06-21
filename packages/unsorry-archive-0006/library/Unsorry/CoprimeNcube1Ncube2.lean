import Mathlib

theorem coprime_ncube1_ncube2 (n : ℕ) : Nat.Coprime (n ^ 3 + 1) (n ^ 3 + 2) := by
  have h1 : Nat.gcd (n ^ 3 + 1) (n ^ 3 + 2) ∣ (n ^ 3 + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n ^ 3 + 1) (n ^ 3 + 2) ∣ (n ^ 3 + 2) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (n ^ 3 + 1) (n ^ 3 + 2) ∣ (n ^ 3 + 1) + 1 := by
    have heq : (n ^ 3 + 1) + 1 = n ^ 3 + 2 := by omega
    rw [heq]
    exact h2
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h1).mp h3)
