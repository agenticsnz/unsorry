import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-168-pow-thirteen-sub-pow-seven`: `168 ∣ n^13 - n^7` over `ℤ`, by a finite `ZMod 168` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_168_pow_thirteen_sub_pow_seven (n : ℤ) : (168 : ℤ) ∣ n ^ 13 - n ^ 7 := by
  have h : ∀ m : ZMod 168, m ^ 13 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 7 : ℤ) : ZMod 168) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 7) 168).mp hz
  exact_mod_cast hdvd
