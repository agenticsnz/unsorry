import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-168-pow-eleven-sub-pow-five`: `168 ∣ n^11 - n^5` over `ℤ`, by a finite `ZMod 168` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_168_pow_eleven_sub_pow_five (n : ℤ) : (168 : ℤ) ∣ n ^ 11 - n ^ 5 := by
  have h : ∀ m : ZMod 168, m ^ 11 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 11 - n ^ 5 : ℤ) : ZMod 168) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 11 - n ^ 5) 168).mp hz
  exact_mod_cast hdvd
