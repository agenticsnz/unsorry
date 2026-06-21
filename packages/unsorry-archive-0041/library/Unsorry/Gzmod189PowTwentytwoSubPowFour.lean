import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-189-pow-twentytwo-sub-pow-four`: `189 ∣ n^22 - n^4` over `ℤ`, by a finite `ZMod 189` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_189_pow_twentytwo_sub_pow_four (n : ℤ) : (189 : ℤ) ∣ n ^ 22 - n ^ 4 := by
  have h : ∀ m : ZMod 189, m ^ 22 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 4 : ℤ) : ZMod 189) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 4) 189).mp hz
  exact_mod_cast hdvd
