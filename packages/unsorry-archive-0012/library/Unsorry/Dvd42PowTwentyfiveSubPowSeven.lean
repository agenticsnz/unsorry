import Mathlib

theorem dvd_42_pow_twentyfive_sub_pow_seven (n : ℤ) :
    (42 : ℤ) ∣ n ^ 25 - n ^ 7 := by
  suffices h : ((n ^ 25 - n ^ 7 : ℤ) : ZMod 42) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 7) 42).mp h
  push_cast
  generalize (n : ZMod 42) = x
  revert x
  decide
