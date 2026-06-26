import Mathlib

theorem three_dvd_n_cubed_add_two_n (n : ℤ) : (3 : ℤ) ∣ (n^3 + 2*n) := by
  suffices h : (((n^3 + 2*n) : ℤ) : ZMod 3) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd ((n^3 + 2*n)) 3).mp h
  push_cast
  generalize (n : ZMod 3) = x
  revert x
  decide
