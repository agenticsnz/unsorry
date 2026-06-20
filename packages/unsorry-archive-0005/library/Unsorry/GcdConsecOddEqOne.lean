import Mathlib

theorem gcd_consec_odd_eq_one (n : ℕ) : Nat.gcd (2 * n + 1) (2 * n + 3) = 1 := by
  have h1 : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ (2 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ (2 * n + 3) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ (2 * n + 1) + 2 := by
    have heq : (2 * n + 1) + 2 = 2 * n + 3 := by omega
    rw [heq]; exact h2
  have h4 : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ 2 := (Nat.dvd_add_right h1).mp h3
  rcases (Nat.dvd_prime Nat.prime_two).mp h4 with h | h
  · exact h
  · exfalso; rw [h] at h1; omega
