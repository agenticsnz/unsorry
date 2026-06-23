import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-64-pow-twentyfour-sub-pow-eight`: `64 ∣ n^24 - n^8` over `ℤ`, by a finite `ZMod 64` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_64_pow_twentyfour_sub_pow_eight (n : ℤ) : (64 : ℤ) ∣ n ^ 24 - n ^ 8 := by
  have h : ∀ m : ZMod 64, m ^ 24 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 8 : ℤ) : ZMod 64) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 8) 64).mp hz
  exact_mod_cast hdvd
