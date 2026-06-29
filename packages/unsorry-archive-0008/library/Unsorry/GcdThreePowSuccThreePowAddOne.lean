import Mathlib

theorem gcd_three_pow_succ_three_pow_add_one (n : ℕ) : Nat.gcd (3 ^ (n + 1)) (3 ^ n + 1) = 1 := by
  have h_not_dvd : ¬ (3 : ℕ) ∣ (3 ^ n + 1) := by
    rcases n with _ | m
    · decide
    · intro hd
      have hdvd : (3 : ℕ) ∣ 3 ^ (m + 1) := dvd_pow_self 3 (Nat.succ_ne_zero m)
      omega
  have hcop3 : Nat.Coprime 3 (3 ^ n + 1) :=
    (Nat.prime_three.coprime_iff_not_dvd).mpr h_not_dvd
  have hcopn : Nat.Coprime (3 ^ n) (3 ^ n + 1) := by
    have a1 : Nat.gcd (3 ^ n) (3 ^ n + 1) ∣ 3 ^ n := Nat.gcd_dvd_left _ _
    have a2 : Nat.gcd (3 ^ n) (3 ^ n + 1) ∣ (3 ^ n + 1) := Nat.gcd_dvd_right _ _
    exact Nat.dvd_one.mp ((Nat.dvd_add_right a1).mp a2)
  show Nat.Coprime (3 ^ (n + 1)) (3 ^ n + 1)
  rw [pow_succ]
  exact hcopn.mul_left hcop3
