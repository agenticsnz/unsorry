import Mathlib

theorem gcd_nsq1_n1_dvd_two (n : ℕ) : Nat.gcd (n ^ 2 + 1) (n + 1) ∣ 2 := by
  have h1 : Nat.gcd (n ^ 2 + 1) (n + 1) ∣ (n ^ 2 + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n ^ 2 + 1) (n + 1) ∣ (n + 1) := Nat.gcd_dvd_right _ _
  have hsq : Nat.gcd (n ^ 2 + 1) (n + 1) ∣ (n + 1) * (n + 1) := h2.mul_right (n + 1)
  have h3 : Nat.gcd (n ^ 2 + 1) (n + 1) ∣ (n ^ 2 + 1) + 2 * n := by
    have heq : (n + 1) * (n + 1) = (n ^ 2 + 1) + 2 * n := by ring
    rwa [heq] at hsq
  have h2n : Nat.gcd (n ^ 2 + 1) (n + 1) ∣ 2 * n := (Nat.dvd_add_right h1).mp h3
  have h4 : Nat.gcd (n ^ 2 + 1) (n + 1) ∣ 2 * n + 2 := by
    have heq2 : 2 * n + 2 = 2 * (n + 1) := by ring
    rw [heq2]; exact h2.mul_left 2
  exact (Nat.dvd_add_right h2n).mp h4
