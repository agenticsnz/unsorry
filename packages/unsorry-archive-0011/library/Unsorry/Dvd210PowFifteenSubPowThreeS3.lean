import Mathlib.Data.ZMod.Basic

theorem dvd_5_pow_fifteen_sub_pow_three (n : ℤ) : (5 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  have h : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 5) = 0 := by
    push_cast
    have hres : ∀ a : ZMod 5, a ^ 15 - a ^ 3 = 0 := by decide
    exact hres (n : ZMod 5)
  exact (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 5).mp h
