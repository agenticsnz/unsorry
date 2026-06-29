import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-216-pow-twentyfive-sub-pow-seven`: `216 ∣ n^25 - n^7` over `ℤ`, by a finite `ZMod 216` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_216_pow_twentyfive_sub_pow_seven (n : ℤ) : (216 : ℤ) ∣ n ^ 25 - n ^ 7 := by
  have h : ∀ m : ZMod 216, m ^ 25 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 7 : ℤ) : ZMod 216) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 7) 216).mp hz
  exact_mod_cast hdvd
