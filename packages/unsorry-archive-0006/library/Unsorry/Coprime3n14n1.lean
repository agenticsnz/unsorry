import Mathlib

theorem coprime_3n1_4n1 (n : ℕ) : Nat.Coprime (3 * n + 1) (4 * n + 1) := by
  have h1 : Nat.gcd (3 * n + 1) (4 * n + 1) ∣ (3 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (3 * n + 1) (4 * n + 1) ∣ (4 * n + 1) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (3 * n + 1) (4 * n + 1) ∣ 3 * (4 * n + 1) := h2.mul_left 3
  have h4 : Nat.gcd (3 * n + 1) (4 * n + 1) ∣ 3 * (4 * n + 1) + 1 := by
    have heq : 3 * (4 * n + 1) + 1 = 4 * (3 * n + 1) := by omega
    rw [heq]
    exact h1.mul_left 4
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h4)
