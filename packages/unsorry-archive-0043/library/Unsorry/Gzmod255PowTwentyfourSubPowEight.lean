import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-255-pow-twentyfour-sub-pow-eight`: `255 ∣ n^24 - n^8` over `ℤ`, by a finite `ZMod 255` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_255_pow_twentyfour_sub_pow_eight (n : ℤ) : (255 : ℤ) ∣ n ^ 24 - n ^ 8 := by
  have h : ∀ m : ZMod 255, m ^ 24 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 8 : ℤ) : ZMod 255) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 8) 255).mp hz
  exact_mod_cast hdvd
