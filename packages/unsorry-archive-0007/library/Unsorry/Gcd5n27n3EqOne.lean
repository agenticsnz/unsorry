import Mathlib

theorem gcd_5n2_7n3_eq_one (n : ℕ) : Nat.gcd (5 * n + 2) (7 * n + 3) = 1 := by
  have h1 : Nat.gcd (5 * n + 2) (7 * n + 3) ∣ (5 * n + 2) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (5 * n + 2) (7 * n + 3) ∣ (7 * n + 3) := Nat.gcd_dvd_right _ _
  have h7 : Nat.gcd (5 * n + 2) (7 * n + 3) ∣ 7 * (5 * n + 2) := h1.mul_left 7
  have h5 : Nat.gcd (5 * n + 2) (7 * n + 3) ∣ 7 * (5 * n + 2) + 1 := by
    have heq : 7 * (5 * n + 2) + 1 = 5 * (7 * n + 3) := by omega
    rw [heq]
    exact h2.mul_left 5
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h7).mp h5)
