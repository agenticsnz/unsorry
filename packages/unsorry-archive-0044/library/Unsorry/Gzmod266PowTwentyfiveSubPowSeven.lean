import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-266-pow-twentyfive-sub-pow-seven`: `266 ∣ n^25 - n^7` over `ℤ`, by a finite `ZMod 266` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_266_pow_twentyfive_sub_pow_seven (n : ℤ) : (266 : ℤ) ∣ n ^ 25 - n ^ 7 := by
  have h : ∀ m : ZMod 266, m ^ 25 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 7 : ℤ) : ZMod 266) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 7) 266).mp hz
  exact_mod_cast hdvd
