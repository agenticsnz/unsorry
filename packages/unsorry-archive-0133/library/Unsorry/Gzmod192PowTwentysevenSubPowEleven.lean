import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-192-pow-twentyseven-sub-pow-eleven`: `192 ∣ n^27 - n^11` over `ℤ`, by a finite `ZMod 192` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_192_pow_twentyseven_sub_pow_eleven (n : ℤ) : (192 : ℤ) ∣ n ^ 27 - n ^ 11 := by
  have h : ∀ m : ZMod 192, m ^ 27 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 11 : ℤ) : ZMod 192) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 11) 192).mp hz
  exact_mod_cast hdvd
