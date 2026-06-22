import Mathlib

theorem gcd_5n3_7n4_eq_one (n : ℕ) : Nat.gcd (5 * n + 3) (7 * n + 4) = 1 := by
  have h1 : Nat.gcd (5 * n + 3) (7 * n + 4) ∣ (5 * n + 3) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (5 * n + 3) (7 * n + 4) ∣ (7 * n + 4) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (5 * n + 3) (7 * n + 4) ∣ 5 * (7 * n + 4) := h2.mul_left 5
  have h4 : Nat.gcd (5 * n + 3) (7 * n + 4) ∣ 5 * (7 * n + 4) + 1 := by
    have heq : 5 * (7 * n + 4) + 1 = 7 * (5 * n + 3) := by omega
    rw [heq]; exact h1.mul_left 7
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h4)
