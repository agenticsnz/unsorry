import Mathlib

theorem dvd_sixty_pow_ten_sub_sq (n : ℤ) : (60 : ℤ) ∣ n ^ 10 - n ^ 2 := by
  suffices h : ((n ^ 10 - n ^ 2 : ℤ) : ZMod 60) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 10 - n ^ 2) 60).mp h
  push_cast
  generalize (n : ZMod 60) = x
  revert x
  decide
