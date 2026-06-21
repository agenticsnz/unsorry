import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-266-pow-twentytwo-sub-pow-four`: `266 ∣ n^22 - n^4` over `ℤ`, by a finite `ZMod 266` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_266_pow_twentytwo_sub_pow_four (n : ℤ) : (266 : ℤ) ∣ n ^ 22 - n ^ 4 := by
  have h : ∀ m : ZMod 266, m ^ 22 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 4 : ℤ) : ZMod 266) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 4) 266).mp hz
  exact_mod_cast hdvd
