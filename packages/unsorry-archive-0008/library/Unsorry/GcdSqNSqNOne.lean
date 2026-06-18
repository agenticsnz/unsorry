import Mathlib

theorem gcd_sq_n_sq_n_one (n : ℕ) : Nat.gcd (n ^ 2) (n ^ 2 + n + 1) = 1 := by
  have h1 : Nat.gcd (n ^ 2) (n ^ 2 + n + 1) ∣ n ^ 2 := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n ^ 2) (n ^ 2 + n + 1) ∣ (n ^ 2 + n + 1) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (n ^ 2) (n ^ 2 + n + 1) ∣ n ^ 2 + (n + 1) := by
    have heq : n ^ 2 + (n + 1) = n ^ 2 + n + 1 := by ring
    rw [heq]; exact h2
  have hn1 : Nat.gcd (n ^ 2) (n ^ 2 + n + 1) ∣ (n + 1) := (Nat.dvd_add_right h1).mp h3
  have hnn : Nat.gcd (n ^ 2) (n ^ 2 + n + 1) ∣ n ^ 2 + n := by
    have hx : Nat.gcd (n ^ 2) (n ^ 2 + n + 1) ∣ n * (n + 1) := hn1.mul_left n
    have heq2 : n * (n + 1) = n ^ 2 + n := by ring
    rwa [heq2] at hx
  have hn : Nat.gcd (n ^ 2) (n ^ 2 + n + 1) ∣ n := (Nat.dvd_add_right h1).mp hnn
  exact Nat.dvd_one.mp ((Nat.dvd_add_right hn).mp hn1)
