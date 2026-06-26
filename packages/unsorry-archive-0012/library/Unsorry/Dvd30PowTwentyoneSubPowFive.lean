import Mathlib

theorem dvd_30_pow_twentyone_sub_pow_five (n : ℤ) :
    (30 : ℤ) ∣ n ^ 21 - n ^ 5 := by
  suffices h : ((n ^ 21 - n ^ 5 : ℤ) : ZMod 30) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 5) 30).mp h
  push_cast
  generalize (n : ZMod 30) = x
  revert x
  decide
