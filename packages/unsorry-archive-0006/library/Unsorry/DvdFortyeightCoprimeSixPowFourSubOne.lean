import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_fortyeight_coprime_six_pow_four_sub_one (n : ℤ) (h2 : ¬ (2 : ℤ) ∣ n) (h3 : ¬ (3 : ℤ) ∣ n) : (48 : ℤ) ∣ n ^ 4 - 1 := by
  have h2' : n % 2 = 1 := by
    rcases Int.emod_two_eq n with h | h
    · exact absurd (Int.dvd_of_emod_eq_zero h) h2
    · exact h
  have h3' : n % 3 = 1 ∨ n % 3 = 2 := by
    have : n % 3 = 0 ∨ n % 3 = 1 ∨ n % 3 = 2 := by omega
    rcases this with h | h | h
    · exact absurd (Int.dvd_of_emod_eq_zero h) h3
    · exact Or.inl h
    · exact Or.inr h
  have hrlow : 0 ≤ n % 48 := Int.emod_nonneg n (by norm_num)
  have hrhigh : n % 48 < 48 := Int.emod_lt_of_pos n (by norm_num)
  set r := n % 48 with hrdef
  have hr2 : r % 2 = 1 := by omega
  have hr3 : r % 3 = 1 ∨ r % 3 = 2 := by omega
  have hmod : (n : ℤ) ≡ r [ZMOD 48] := by
    unfold Int.ModEq
    rw [hrdef]
    exact (Int.emod_emod_of_dvd n (dvd_refl 48)).symm
  have hmod4 : n ^ 4 ≡ r ^ 4 [ZMOD 48] := hmod.pow 4
  have hrdvd : (48 : ℤ) ∣ r ^ 4 - 1 := by
    interval_cases r <;> first | (exfalso; omega) | decide
  have hnr : (48 : ℤ) ∣ n ^ 4 - r ^ 4 := (Int.modEq_iff_dvd.mp hmod4.symm)
  have hfinal : n ^ 4 - 1 = (n ^ 4 - r ^ 4) + (r ^ 4 - 1) := by ring
  rw [hfinal]
  exact dvd_add hnr hrdvd