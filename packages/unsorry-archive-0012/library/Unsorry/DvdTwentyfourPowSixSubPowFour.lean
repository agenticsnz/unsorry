import Mathlib

theorem dvd_twentyfour_pow_six_sub_pow_four (n : ℤ) : (24 : ℤ) ∣ n ^ 6 - n ^ 4 := by
  suffices h : ((n ^ 6 - n ^ 4 : ℤ) : ZMod 24) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 6 - n ^ 4) 24).mp h
  push_cast
  generalize (n : ZMod 24) = x
  revert x
  decide
