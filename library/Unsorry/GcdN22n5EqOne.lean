import Mathlib

theorem gcd_n2_2n5_eq_one (n : ℕ) : Nat.gcd (n + 2) (2 * n + 5) = 1 := by
  have h1 : Nat.gcd (n + 2) (2 * n + 5) ∣ (n + 2) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 2) (2 * n + 5) ∣ (2 * n + 5) := Nat.gcd_dvd_right _ _
  have h4 : Nat.gcd (n + 2) (2 * n + 5) ∣ 2 * (n + 2) := h1.mul_left 2
  have h5 : Nat.gcd (n + 2) (2 * n + 5) ∣ 2 * (n + 2) + 1 := by
    have heq : 2 * (n + 2) + 1 = 2 * n + 5 := by omega
    rw [heq]
    exact h2
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h4).mp h5)
