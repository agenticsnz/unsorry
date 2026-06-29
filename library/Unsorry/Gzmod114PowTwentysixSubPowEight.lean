import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-114-pow-twentysix-sub-pow-eight`: `114 ∣ n^26 - n^8` over `ℤ`, by a finite `ZMod 114` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_114_pow_twentysix_sub_pow_eight (n : ℤ) : (114 : ℤ) ∣ n ^ 26 - n ^ 8 := by
  have h : ∀ m : ZMod 114, m ^ 26 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 8 : ℤ) : ZMod 114) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 8) 114).mp hz
  exact_mod_cast hdvd
