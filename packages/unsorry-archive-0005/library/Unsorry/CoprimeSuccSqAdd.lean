import Mathlib

theorem coprime_succ_sq_add (n : ℕ) : Nat.Coprime (n + 1) (n ^ 2 + n + 1) := by
  have h1 : Nat.gcd (n + 1) (n ^ 2 + n + 1) ∣ (n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (n + 1) (n ^ 2 + n + 1) ∣ (n ^ 2 + n + 1) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd (n + 1) (n ^ 2 + n + 1) ∣ n * (n + 1) := h1.mul_left n
  have h4 : Nat.gcd (n + 1) (n ^ 2 + n + 1) ∣ n * (n + 1) + 1 := by
    have heq : n * (n + 1) + 1 = n ^ 2 + n + 1 := by ring
    rw [heq]
    exact h2
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h4)
