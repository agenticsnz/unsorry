import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-360-pow-fifteen-sub-pow-three`: `360 ∣ n^15 - n^3` over `ℤ`, by a finite `ZMod 360` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_360_pow_fifteen_sub_pow_three (n : ℤ) : (360 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  have h : ∀ m : ZMod 360, m ^ 15 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 360) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 360).mp hz
  exact_mod_cast hdvd
