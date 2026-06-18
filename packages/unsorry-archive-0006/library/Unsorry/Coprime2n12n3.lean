import Mathlib

theorem coprime_2n1_2n3 (n : ℕ) : Nat.Coprime (2 * n + 1) (2 * n + 3) := by
  have h1 : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ (2 * n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ (2 * n + 3) := Nat.gcd_dvd_right _ _
  have hd2 : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ 2 := by
    have h3 : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ (2 * n + 1) + 2 := by
      have heq : (2 * n + 1) + 2 = 2 * n + 3 := by omega
      rw [heq]; exact h2
    exact (Nat.dvd_add_right h1).mp h3
  have hdn : Nat.gcd (2 * n + 1) (2 * n + 3) ∣ 2 * n := by
    have hm := hd2.mul_left n
    have heq : n * 2 = 2 * n := by omega
    rwa [heq] at hm
  exact Nat.dvd_one.mp ((Nat.dvd_add_right hdn).mp h1)
