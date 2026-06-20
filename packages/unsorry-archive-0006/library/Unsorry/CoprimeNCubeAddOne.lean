import Mathlib

theorem coprime_n_cube_add_one (n : ℕ) : Nat.Coprime n (n ^ 3 + 1) := by
  have h1 : Nat.gcd n (n ^ 3 + 1) ∣ n := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd n (n ^ 3 + 1) ∣ (n ^ 3 + 1) := Nat.gcd_dvd_right _ _
  have h3 : Nat.gcd n (n ^ 3 + 1) ∣ n ^ 3 := by
    have hm := h1.mul_right (n ^ 2)
    have heq : n * n ^ 2 = n ^ 3 := by ring
    rwa [heq] at hm
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h2)
