import Mathlib

theorem six_dvd_n_mul_succ_mul_two_n_add_one (n : ℤ) :
    (6 : ℤ) ∣ n * (n + 1) * (2 * n + 1) := by
  suffices h : ((n * (n + 1) * (2 * n + 1) : ℤ) : ZMod 6) = 0 by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1) * (2 * n + 1)) 6).mp h
  push_cast
  generalize (n : ZMod 6) = x
  revert x
  decide
