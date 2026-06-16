import Mathlib

theorem coprime_twopow_sub_one_two (n : ℕ) (hn : 0 < n) : Nat.Coprime (2 ^ n - 1) 2 := by
  have h1 : Nat.gcd (2 ^ n - 1) 2 ∣ (2 ^ n - 1) := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd (2 ^ n - 1) 2 ∣ 2 := Nat.gcd_dvd_right _ _
  rcases (Nat.dvd_prime Nat.prime_two).mp h2 with h | h
  · exact h
  · exfalso
    rw [h] at h1
    have h2n : (2 : ℕ) ∣ 2 ^ n := dvd_pow_self 2 hn.ne'
    have hp : 0 < 2 ^ n := pow_pos (by norm_num) n
    omega
