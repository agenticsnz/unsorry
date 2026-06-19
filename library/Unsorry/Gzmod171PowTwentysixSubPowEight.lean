import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-171-pow-twentysix-sub-pow-eight`: `171 ∣ n^26 - n^8` over `ℤ`, by a finite `ZMod 171` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_171_pow_twentysix_sub_pow_eight (n : ℤ) : (171 : ℤ) ∣ n ^ 26 - n ^ 8 := by
  have h : ∀ m : ZMod 171, m ^ 26 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 8 : ℤ) : ZMod 171) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 8) 171).mp hz
  exact_mod_cast hdvd
