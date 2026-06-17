import Mathlib

set_option maxRecDepth 8000 in
theorem prime_pow_six_mod_504 (p : ℕ) (hp : Nat.Prime p) (h : 7 < p) : p ^ 6 % 504 = 1 := by
  -- p is coprime to 2, 3, 7 (and hence to 8, 9, 7) since p is prime and p > 7
  have hp2 : ¬ p ∣ 2 := fun hd => by
    have := Nat.le_of_dvd (by norm_num) hd; omega
  have hp3 : ¬ p ∣ 3 := fun hd => by
    have := Nat.le_of_dvd (by norm_num) hd; omega
  have hp7 : ¬ p ∣ 7 := fun hd => by
    have := Nat.le_of_dvd (by norm_num) hd; omega
  have cop2 : Nat.Coprime p 2 := (Nat.Prime.coprime_iff_not_dvd hp).mpr hp2
  have cop3 : Nat.Coprime p 3 := (Nat.Prime.coprime_iff_not_dvd hp).mpr hp3
  have cop7 : Nat.Coprime p 7 := (Nat.Prime.coprime_iff_not_dvd hp).mpr hp7
  -- coprimality to 8 and 9
  have cop8 : Nat.Coprime p 8 := by
    have : (8 : ℕ) = 2 ^ 3 := by norm_num
    rw [this]; exact cop2.pow_right 3
  have cop9 : Nat.Coprime p 9 := by
    have : (9 : ℕ) = 3 ^ 2 := by norm_num
    rw [this]; exact cop3.pow_right 2
  -- mod 7 : Euler / Fermat, totient 7 = 6
  have m7 : p ^ 6 ≡ 1 [MOD 7] := by
    have ht : Nat.totient 7 = 6 := by decide
    have := Nat.ModEq.pow_totient cop7
    rwa [ht] at this
  -- mod 9 : Euler, totient 9 = 6
  have m9 : p ^ 6 ≡ 1 [MOD 9] := by
    have ht : Nat.totient 9 = 6 := by decide
    have := Nat.ModEq.pow_totient cop9
    rwa [ht] at this
  -- mod 8 : reduce to p % 8 and decide over coprime residues
  have m8 : p ^ 6 ≡ 1 [MOD 8] := by
    have hred : p ^ 6 ≡ (p % 8) ^ 6 [MOD 8] :=
      Nat.ModEq.pow 6 (Nat.mod_modEq p 8).symm
    have hlt : p % 8 < 8 := Nat.mod_lt p (by norm_num)
    have hcr : Nat.Coprime (p % 8) 8 :=
      (ZMod.coprime_mod_iff_coprime p 8).mpr cop8
    have hall : ∀ r, r < 8 → Nat.Coprime r 8 → r ^ 6 % 8 = 1 := by decide
    have hkey : (p % 8) ^ 6 % 8 = 1 := hall (p % 8) hlt hcr
    -- turn hkey into a ModEq
    calc p ^ 6 ≡ (p % 8) ^ 6 [MOD 8] := hred
      _ ≡ 1 [MOD 8] := by
            unfold Nat.ModEq
            rw [hkey]
  -- combine mod 7 and mod 8 -> mod 56
  have c78 : Nat.Coprime 7 8 := by decide
  have m56 : p ^ 6 ≡ 1 [MOD 56] := by
    have := (Nat.modEq_and_modEq_iff_modEq_mul c78).mp ⟨m7, m8⟩
    norm_num at this
    exact this
  -- combine mod 56 and mod 9 -> mod 504
  have c569 : Nat.Coprime 56 9 := by decide
  have m504 : p ^ 6 ≡ 1 [MOD 504] := by
    have := (Nat.modEq_and_modEq_iff_modEq_mul c569).mp ⟨m56, m9⟩
    norm_num at this
    exact this
  -- conclude: 1 % 504 = 1
  have : p ^ 6 % 504 = 1 % 504 := m504
  simpa using this