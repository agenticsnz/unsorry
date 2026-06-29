import Mathlib

theorem dvd_3_pow_fifteen_sub_pow_three (n : ℤ) : (3 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  suffices h : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 3) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 3).mp h
  push_cast
  generalize (n : ZMod 3) = x
  revert x
  decide
