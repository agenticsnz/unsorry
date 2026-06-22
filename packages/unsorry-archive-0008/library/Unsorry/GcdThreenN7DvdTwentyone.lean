import Mathlib

theorem gcd_threen_n7_dvd_twentyone (n : ℕ) : Nat.gcd (3 * n) (n + 7) ∣ 21 := by
  have h1 : Nat.gcd (3 * n) (n + 7) ∣ (3 * n) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (3 * n) (n + 7) ∣ (n + 7) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (3 * n) (n + 7) ∣ 3 * n + 21 := by
    have heq : 3 * n + 21 = 3 * (n + 7) := by ring
    rw [heq]; exact h2.mul_left 3
  exact (Nat.dvd_add_right h1).mp h3
