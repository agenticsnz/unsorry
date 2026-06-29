import Mathlib

theorem dvd_twentyfour_pow_five_sub_pow_three (n : ℤ) : (24 : ℤ) ∣ n ^ 5 - n ^ 3 := by
  suffices h : ((n ^ 5 - n ^ 3 : ℤ) : ZMod 24) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 5 - n ^ 3) 24).mp h
  push_cast
  generalize (n : ZMod 24) = x
  revert x
  decide
