import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-108-pow-twentysix-sub-pow-eight`: `108 ∣ n^26 - n^8` over `ℤ`, by a finite `ZMod 108` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_108_pow_twentysix_sub_pow_eight (n : ℤ) : (108 : ℤ) ∣ n ^ 26 - n ^ 8 := by
  have h : ∀ m : ZMod 108, m ^ 26 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 8 : ℤ) : ZMod 108) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 8) 108).mp hz
  exact_mod_cast hdvd
