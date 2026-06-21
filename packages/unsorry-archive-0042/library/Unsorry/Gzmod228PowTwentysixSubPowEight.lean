import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-228-pow-twentysix-sub-pow-eight`: `228 ∣ n^26 - n^8` over `ℤ`, by a finite `ZMod 228` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_228_pow_twentysix_sub_pow_eight (n : ℤ) : (228 : ℤ) ∣ n ^ 26 - n ^ 8 := by
  have h : ∀ m : ZMod 228, m ^ 26 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 8 : ℤ) : ZMod 228) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 8) 228).mp hz
  exact_mod_cast hdvd
