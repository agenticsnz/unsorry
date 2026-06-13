import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Nat.GCD.Basic

theorem coprime_two_pow_mersenne (p : ℕ) : Nat.Coprime (2 ^ (p - 1)) (2 ^ p - 1) := by
  rcases Nat.eq_zero_or_pos p with rfl | hp
  · decide
  · have hp1 : 1 ≤ 2 ^ p := Nat.one_le_two_pow
    have h2p : 2 ∣ 2 ^ p := dvd_pow_self 2 hp.ne'
    have hodd : ¬ 2 ∣ (2 ^ p - 1) := by omega
    have hcop2 : Nat.Coprime 2 (2 ^ p - 1) :=
      (Nat.prime_two.coprime_iff_not_dvd).mpr hodd
    exact Nat.Coprime.pow_left (p - 1) hcop2
