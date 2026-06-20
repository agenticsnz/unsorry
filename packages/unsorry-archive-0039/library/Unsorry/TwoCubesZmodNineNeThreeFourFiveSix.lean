import Mathlib

theorem two_cubes_zmod_nine_ne_three_four_five_six (a b : ℤ) :
    ¬ ((a^3 + b^3) % 9 = 3 ∨ (a^3 + b^3) % 9 = 4 ∨ (a^3 + b^3) % 9 = 5 ∨ (a^3 + b^3) % 9 = 6) := by
  have hca : a ≡ a % 9 [ZMOD 9] := (Int.emod_emod_of_dvd a (dvd_refl 9)).symm
  have hcb : b ≡ b % 9 [ZMOD 9] := (Int.emod_emod_of_dvd b (dvd_refl 9)).symm
  have key : (a^3 + b^3) ≡ ((a % 9)^3 + (b % 9)^3) [ZMOD 9] :=
    Int.ModEq.add (hca.pow 3) (hcb.pow 3)
  have keq : (a^3 + b^3) % 9 = ((a % 9)^3 + (b % 9)^3) % 9 := key
  rw [keq]
  have ha0 := Int.emod_nonneg a (by norm_num : (9:ℤ) ≠ 0)
  have ha9 := Int.emod_lt_of_pos a (by norm_num : (0:ℤ) < 9)
  have hb0 := Int.emod_nonneg b (by norm_num : (9:ℤ) ≠ 0)
  have hb9 := Int.emod_lt_of_pos b (by norm_num : (0:ℤ) < 9)
  interval_cases (a % 9) <;> interval_cases (b % 9) <;> decide