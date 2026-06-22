import Mathlib

theorem dvd_twentyfour_pow_seven_sub_pow_five (n : ℤ) : (24 : ℤ) ∣ n ^ 7 - n ^ 5 := by
  suffices h : ((n ^ 7 - n ^ 5 : ℤ) : ZMod 24) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 7 - n ^ 5) 24).mp h
  push_cast
  generalize (n : ZMod 24) = x
  revert x
  decide
