import Mathlib

set_option maxRecDepth 8000 in
theorem prime_pow_eight_mod_480 (p : ℕ) (hp : Nat.Prime p) (h : 5 < p) : p ^ 8 % 480 = 1 := by
  have h2 : ¬ (2 ∣ p) := by
    intro hd
    have := (Nat.prime_dvd_prime_iff_eq Nat.prime_two hp).mp hd
    omega
  have h3 : ¬ (3 ∣ p) := by
    intro hd
    have := (Nat.prime_dvd_prime_iff_eq Nat.prime_three hp).mp hd
    omega
  have h5 : ¬ (5 ∣ p) := by
    intro hd
    have h5p : Nat.Prime 5 := by norm_num
    have := (Nat.prime_dvd_prime_iff_eq h5p hp).mp hd
    omega
  rw [Nat.dvd_iff_mod_eq_zero] at h2 h3 h5
  -- residue facts
  have m32 : p ^ 8 % 32 = 1 := by
    have e : p ^ 8 % 32 = (p % 32) ^ 8 % 32 := by rw [Nat.pow_mod]
    have hlo : 0 ≤ p % 32 := Nat.zero_le _
    have hhi : p % 32 < 32 := Nat.mod_lt _ (by norm_num)
    have hp2 : p % 32 % 2 = 1 := by omega
    rw [e]
    interval_cases (p % 32) <;> simp_all
  have m3 : p ^ 8 % 3 = 1 := by
    have e : p ^ 8 % 3 = (p % 3) ^ 8 % 3 := by rw [Nat.pow_mod]
    have hlo : 0 ≤ p % 3 := Nat.zero_le _
    have hhi : p % 3 < 3 := Nat.mod_lt _ (by norm_num)
    rw [e]
    interval_cases (p % 3) <;> simp_all
  have m5 : p ^ 8 % 5 = 1 := by
    have e : p ^ 8 % 5 = (p % 5) ^ 8 % 5 := by rw [Nat.pow_mod]
    have hlo : 0 ≤ p % 5 := Nat.zero_le _
    have hhi : p % 5 < 5 := Nat.mod_lt _ (by norm_num)
    rw [e]
    interval_cases (p % 5) <;> simp_all
  -- combine via CRT: 480 = 32 * 3 * 5
  omega