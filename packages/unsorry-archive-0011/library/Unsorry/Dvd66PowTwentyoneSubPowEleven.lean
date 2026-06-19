import Mathlib.Data.ZMod.Basic

theorem dvd_66_pow_twentyone_sub_pow_eleven (n : ℤ) : (66 : ℤ) ∣ n ^ 21 - n ^ 11 := by
  have hz : ((n ^ 21 - n ^ 11 : ℤ) : ZMod 66) = 0 := by
    simpa using (by decide : ∀ a : ZMod 66, a ^ 21 - a ^ 11 = 0) (n : ZMod 66)
  simpa using (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 11) 66).mp hz
