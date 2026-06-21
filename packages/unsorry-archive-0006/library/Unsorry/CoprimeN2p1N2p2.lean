import Mathlib

theorem coprime_n2p1_n2p2 (n : ℕ) : Nat.Coprime (n ^ 2 + 1) (n ^ 2 + 2) := by
  have h1 : Nat.gcd (n ^ 2 + 1) (n ^ 2 + 2) ∣ (n ^ 2 + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n ^ 2 + 1) (n ^ 2 + 2) ∣ (n ^ 2 + 2) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (n ^ 2 + 1) (n ^ 2 + 2) ∣ (n ^ 2 + 1) + 1 := by
    have heq : (n ^ 2 + 1) + 1 = n ^ 2 + 2 := by omega
    rw [heq]
    exact h2
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h1).mp h3)
