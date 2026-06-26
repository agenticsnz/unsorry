import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-320-pow-twentyfive-sub-pow-nine`: `320 ∣ n^25 - n^9` over `ℤ`, by a finite `ZMod 320` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_320_pow_twentyfive_sub_pow_nine (n : ℤ) : (320 : ℤ) ∣ n ^ 25 - n ^ 9 := by
  have h : ∀ m : ZMod 320, m ^ 25 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 9 : ℤ) : ZMod 320) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 9) 320).mp hz
  exact_mod_cast hdvd
