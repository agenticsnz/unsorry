import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-192-pow-twentyeight-sub-pow-twelve`: `192 ∣ n^28 - n^12` over `ℤ`, by a finite `ZMod 192` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_192_pow_twentyeight_sub_pow_twelve (n : ℤ) : (192 : ℤ) ∣ n ^ 28 - n ^ 12 := by
  have h : ∀ m : ZMod 192, m ^ 28 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 28 - n ^ 12 : ℤ) : ZMod 192) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 28 - n ^ 12) 192).mp hz
  exact_mod_cast hdvd
