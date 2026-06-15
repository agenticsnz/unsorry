import Mathlib

theorem gcd_6n5_6n11_eq_one (n : ℕ) : Nat.gcd (6 * n + 5) (6 * n + 11) = 1 := by
  have h1 : Nat.gcd (6 * n + 5) (6 * n + 11) ∣ (6 * n + 5) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (6 * n + 5) (6 * n + 11) ∣ (6 * n + 11) := Nat.gcd_dvd_right _ _
  have hd6 : Nat.gcd (6 * n + 5) (6 * n + 11) ∣ 6 := by
    have h3 : Nat.gcd (6 * n + 5) (6 * n + 11) ∣ (6 * n + 5) + 6 := by
      have heq : (6 * n + 5) + 6 = 6 * n + 11 := by omega
      rw [heq]; exact h2
    exact (Nat.dvd_add_right h1).mp h3
  have hd6n : Nat.gcd (6 * n + 5) (6 * n + 11) ∣ 6 * n := by
    have hm := hd6.mul_left n
    have heq : n * 6 = 6 * n := by omega
    rwa [heq] at hm
  have hd5 : Nat.gcd (6 * n + 5) (6 * n + 11) ∣ 5 := (Nat.dvd_add_right hd6n).mp h1
  have hd1 : Nat.gcd (6 * n + 5) (6 * n + 11) ∣ 1 := by
    have h6 : Nat.gcd (6 * n + 5) (6 * n + 11) ∣ 5 + 1 := by
      have heq : (5 : ℕ) + 1 = 6 := by omega
      rw [heq]; exact hd6
    exact (Nat.dvd_add_right hd5).mp h6
  exact Nat.dvd_one.mp hd1
