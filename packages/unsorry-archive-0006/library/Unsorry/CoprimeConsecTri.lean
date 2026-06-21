import Mathlib

theorem coprime_consec_tri (n : ℕ) : Nat.Coprime (2 * n + 1) (n * (n + 1)) := by
  have h1 : Nat.gcd (2 * n + 1) (n * (n + 1)) ∣ (2 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n + 1) (n * (n + 1)) ∣ (n * (n + 1)) := Nat.gcd_dvd_right _ _
  have h4 : Nat.gcd (2 * n + 1) (n * (n + 1)) ∣ 4 * (n * (n + 1)) := h2.mul_left 4
  have h3 : Nat.gcd (2 * n + 1) (n * (n + 1)) ∣ 4 * (n * (n + 1)) + 1 := by
    have heq : 4 * (n * (n + 1)) + 1 = (2 * n + 1) * (2 * n + 1) := by ring
    rw [heq]; exact h1.mul_right (2 * n + 1)
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h4).mp h3)
