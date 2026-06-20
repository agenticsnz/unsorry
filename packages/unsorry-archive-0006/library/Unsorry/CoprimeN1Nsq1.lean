import Mathlib

theorem coprime_n1_nsq1 (n : ℕ) : Nat.gcd (n + 1) (n ^ 2 + 1) ∣ 2 := by
  have h1 : Nat.gcd (n + 1) (n ^ 2 + 1) ∣ (n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 1) (n ^ 2 + 1) ∣ (n ^ 2 + 1) := Nat.gcd_dvd_right _ _
  have hsq : Nat.gcd (n + 1) (n ^ 2 + 1) ∣ (n + 1) * (n + 1) := h1.mul_right (n + 1)
  have h2n : Nat.gcd (n + 1) (n ^ 2 + 1) ∣ 2 * n := by
    have e1 : (n + 1) * (n + 1) = (n ^ 2 + 1) + 2 * n := by ring
    rw [e1] at hsq
    exact (Nat.dvd_add_right h2).mp hsq
  have h2n2 : Nat.gcd (n + 1) (n ^ 2 + 1) ∣ 2 * n + 2 := by
    have e2 : 2 * n + 2 = 2 * (n + 1) := by omega
    rw [e2]
    exact h1.mul_left 2
  exact (Nat.dvd_add_right h2n).mp h2n2
