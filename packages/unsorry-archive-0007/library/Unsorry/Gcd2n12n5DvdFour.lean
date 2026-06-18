import Mathlib

theorem gcd_2n1_2n5_dvd_four (n : ℕ) : Nat.gcd (2 * n + 1) (2 * n + 5) ∣ 4 := by
  have h1 : Nat.gcd (2 * n + 1) (2 * n + 5) ∣ (2 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n + 1) (2 * n + 5) ∣ (2 * n + 1) + 4 := by
    have heq : 2 * n + 5 = (2 * n + 1) + 4 := by omega
    rw [← heq]
    exact Nat.gcd_dvd_right _ _
  exact (Nat.dvd_add_right h1).mp h2
