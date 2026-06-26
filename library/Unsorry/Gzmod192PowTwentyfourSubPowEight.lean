import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-192-pow-twentyfour-sub-pow-eight`: `192 ∣ n^24 - n^8` over `ℤ`, by a finite `ZMod 192` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_192_pow_twentyfour_sub_pow_eight (n : ℤ) : (192 : ℤ) ∣ n ^ 24 - n ^ 8 := by
  have h : ∀ m : ZMod 192, m ^ 24 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 8 : ℤ) : ZMod 192) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 8) 192).mp hz
  exact_mod_cast hdvd
