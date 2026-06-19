import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-266-pow-thirty-sub-pow-twelve`: `266 ∣ n^30 - n^12` over `ℤ`, by a finite `ZMod 266` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_266_pow_thirty_sub_pow_twelve (n : ℤ) : (266 : ℤ) ∣ n ^ 30 - n ^ 12 := by
  have h : ∀ m : ZMod 266, m ^ 30 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 30 - n ^ 12 : ℤ) : ZMod 266) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 30 - n ^ 12) 266).mp hz
  exact_mod_cast hdvd
