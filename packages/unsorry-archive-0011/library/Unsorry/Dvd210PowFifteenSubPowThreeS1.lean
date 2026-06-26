import Mathlib

theorem dvd_2_pow_fifteen_sub_pow_three (n : ℤ) : (2 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  suffices h : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 2) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 2).mp h
  push_cast
  generalize (n : ZMod 2) = x
  revert x
  decide
