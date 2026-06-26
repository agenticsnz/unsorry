import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-399-pow-twentytwo-sub-pow-four`: `399 ∣ n^22 - n^4` over `ℤ`, by a finite `ZMod 399` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_399_pow_twentytwo_sub_pow_four (n : ℤ) : (399 : ℤ) ∣ n ^ 22 - n ^ 4 := by
  have h : ∀ m : ZMod 399, m ^ 22 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 4 : ℤ) : ZMod 399) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 4) 399).mp hz
  exact_mod_cast hdvd
