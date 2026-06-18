import Mathlib

theorem gcd_4n1_6n1_dvd_two (n : ℕ) : Nat.gcd (4 * n + 1) (6 * n + 1) ∣ 2 := by
  have h1 : Nat.gcd (4 * n + 1) (6 * n + 1) ∣ (4 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (4 * n + 1) (6 * n + 1) ∣ (6 * n + 1) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (4 * n + 1) (6 * n + 1) ∣ 2 * (6 * n + 1) := h2.mul_left 2
  have h4 : Nat.gcd (4 * n + 1) (6 * n + 1) ∣ 2 * (6 * n + 1) + 1 := by
    have heq : 2 * (6 * n + 1) + 1 = 3 * (4 * n + 1) := by omega
    rw [heq]
    exact h1.mul_left 3
  have hone : Nat.gcd (4 * n + 1) (6 * n + 1) ∣ 1 := (Nat.dvd_add_right h3).mp h4
  exact hone.trans (one_dvd 2)
