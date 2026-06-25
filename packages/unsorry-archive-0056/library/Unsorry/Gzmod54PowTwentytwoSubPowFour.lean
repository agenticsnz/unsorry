import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-54-pow-twentytwo-sub-pow-four`: `54 ∣ n^22 - n^4` over `ℤ`, by a finite `ZMod 54` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_54_pow_twentytwo_sub_pow_four (n : ℤ) : (54 : ℤ) ∣ n ^ 22 - n ^ 4 := by
  have h : ∀ m : ZMod 54, m ^ 22 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 4 : ℤ) : ZMod 54) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 4) 54).mp hz
  exact_mod_cast hdvd
