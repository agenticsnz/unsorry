import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-133-pow-twentysix-sub-pow-eight`: `133 ∣ n^26 - n^8` over `ℤ`, by a finite `ZMod 133` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_133_pow_twentysix_sub_pow_eight (n : ℤ) : (133 : ℤ) ∣ n ^ 26 - n ^ 8 := by
  have h : ∀ m : ZMod 133, m ^ 26 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 8 : ℤ) : ZMod 133) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 8) 133).mp hz
  exact_mod_cast hdvd
