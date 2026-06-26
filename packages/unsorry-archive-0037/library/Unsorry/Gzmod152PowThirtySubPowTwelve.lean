import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-152-pow-thirty-sub-pow-twelve`: `152 ∣ n^30 - n^12` over `ℤ`, by a finite `ZMod 152` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_152_pow_thirty_sub_pow_twelve (n : ℤ) : (152 : ℤ) ∣ n ^ 30 - n ^ 12 := by
  have h : ∀ m : ZMod 152, m ^ 30 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 30 - n ^ 12 : ℤ) : ZMod 152) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 30 - n ^ 12) 152).mp hz
  exact_mod_cast hdvd
