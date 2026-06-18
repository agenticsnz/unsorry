import Mathlib

theorem gcd_3n1_9n4_eq_one (n : ℕ) : Nat.gcd (3 * n + 1) (9 * n + 4) = 1 := by
  have h1 : Nat.gcd (3 * n + 1) (9 * n + 4) ∣ (3 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (3 * n + 1) (9 * n + 4) ∣ (9 * n + 4) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (3 * n + 1) (9 * n + 4) ∣ 3 * (3 * n + 1) := h1.mul_left 3
  have h4 : Nat.gcd (3 * n + 1) (9 * n + 4) ∣ 3 * (3 * n + 1) + 1 := by
    have heq : 3 * (3 * n + 1) + 1 = 9 * n + 4 := by omega
    rw [heq]; exact h2
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h4)
