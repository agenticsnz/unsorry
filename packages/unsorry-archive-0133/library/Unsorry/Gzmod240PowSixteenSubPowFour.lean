import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-240-pow-sixteen-sub-pow-four`: `240 ∣ n^16 - n^4` over `ℤ`, by a finite `ZMod 240` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_240_pow_sixteen_sub_pow_four (n : ℤ) : (240 : ℤ) ∣ n ^ 16 - n ^ 4 := by
  have h : ∀ m : ZMod 240, m ^ 16 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 4 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 4) 240).mp hz
  exact_mod_cast hdvd
