import Mathlib

theorem gcd_np1_2np1_eq_one (n : ℕ) : Nat.gcd (n + 1) (2 * n + 1) = 1 := by
  have h1 : Nat.gcd (n + 1) (2 * n + 1) ∣ (n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 1) (2 * n + 1) ∣ (2 * n + 1) := Nat.gcd_dvd_right _ _
  have h4 : Nat.gcd (n + 1) (2 * n + 1) ∣ (2 * n + 1) + 1 := by
    have heq : (2 * n + 1) + 1 = 2 * (n + 1) := by omega
    rw [heq]
    exact h1.mul_left 2
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h2).mp h4)
