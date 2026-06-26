import Mathlib

theorem gcd_two_pow_add_one_sub_one_dvd_two (n : ℕ) : Nat.gcd (2 ^ n + 1) (2 ^ n - 1) ∣ 2 := by
  have h1 : Nat.gcd (2 ^ n + 1) (2 ^ n - 1) ∣ (2 ^ n + 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 ^ n + 1) (2 ^ n - 1) ∣ (2 ^ n - 1) := Nat.gcd_dvd_right _ _
  have hp : 0 < 2 ^ n := pow_pos (by norm_num) n
  have h3 : Nat.gcd (2 ^ n + 1) (2 ^ n - 1) ∣ (2 ^ n - 1) + 2 := by
    have heq : (2 ^ n - 1) + 2 = 2 ^ n + 1 := by omega
    rw [heq]; exact h1
  exact (Nat.dvd_add_right h2).mp h3
