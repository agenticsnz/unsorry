import Mathlib

theorem gcd_2n5_3n7_eq_one (n : ℕ) : Nat.gcd (2 * n + 5) (3 * n + 7) = 1 := by
  have h1 : Nat.gcd (2 * n + 5) (3 * n + 7) ∣ (2 * n + 5) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n + 5) (3 * n + 7) ∣ (3 * n + 7) := Nat.gcd_dvd_right _ _
  have h4 : Nat.gcd (2 * n + 5) (3 * n + 7) ∣ 2 * (3 * n + 7) := h2.mul_left 2
  have h5 : Nat.gcd (2 * n + 5) (3 * n + 7) ∣ 2 * (3 * n + 7) + 1 := by
    have heq : 2 * (3 * n + 7) + 1 = 3 * (2 * n + 5) := by omega
    rw [heq]
    exact h1.mul_left 3
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h4).mp h5)
