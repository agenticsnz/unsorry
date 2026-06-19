import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-152-pow-twentytwo-sub-pow-four`: `152 ∣ n^22 - n^4` over `ℤ`, by a finite `ZMod 152` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_152_pow_twentytwo_sub_pow_four (n : ℤ) : (152 : ℤ) ∣ n ^ 22 - n ^ 4 := by
  have h : ∀ m : ZMod 152, m ^ 22 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 4 : ℤ) : ZMod 152) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 4) 152).mp hz
  exact_mod_cast hdvd
