import Mathlib

theorem gcd_2n3_4n5_dvd_two (n : ℕ) : Nat.gcd (2 * n + 3) (4 * n + 5) ∣ 2 := by
  have h1 : Nat.gcd (2 * n + 3) (4 * n + 5) ∣ (2 * n + 3) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n + 3) (4 * n + 5) ∣ (4 * n + 5) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (2 * n + 3) (4 * n + 5) ∣ 2 * (2 * n + 3) := h1.mul_left 2
  have h4 : Nat.gcd (2 * n + 3) (4 * n + 5) ∣ (4 * n + 5) + 1 := by
    have heq : (4 * n + 5) + 1 = 2 * (2 * n + 3) := by omega
    rw [heq]; exact h3
  have hone : Nat.gcd (2 * n + 3) (4 * n + 5) ∣ 1 := (Nat.dvd_add_right h2).mp h4
  exact hone.trans (one_dvd 2)
