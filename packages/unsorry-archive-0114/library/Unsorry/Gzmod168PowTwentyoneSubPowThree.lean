import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-168-pow-twentyone-sub-pow-three`: `168 ∣ n^21 - n^3` over `ℤ`, by a finite `ZMod 168` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_168_pow_twentyone_sub_pow_three (n : ℤ) : (168 : ℤ) ∣ n ^ 21 - n ^ 3 := by
  have h : ∀ m : ZMod 168, m ^ 21 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 3 : ℤ) : ZMod 168) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 3) 168).mp hz
  exact_mod_cast hdvd
