import Mathlib

theorem gcd_3n2_4n3_eq_one (n : ℕ) : Nat.gcd (3 * n + 2) (4 * n + 3) = 1 := by
  have h1 : Nat.gcd (3 * n + 2) (4 * n + 3) ∣ (3 * n + 2) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (3 * n + 2) (4 * n + 3) ∣ (4 * n + 3) := Nat.gcd_dvd_right _ _
  have h4 : Nat.gcd (3 * n + 2) (4 * n + 3) ∣ 4 * (3 * n + 2) := h1.mul_left 4
  have h5 : Nat.gcd (3 * n + 2) (4 * n + 3) ∣ 4 * (3 * n + 2) + 1 := by
    have heq : 4 * (3 * n + 2) + 1 = 3 * (4 * n + 3) := by omega
    rw [heq]
    exact h2.mul_left 3
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h4).mp h5)
