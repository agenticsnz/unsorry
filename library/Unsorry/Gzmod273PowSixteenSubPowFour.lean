import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-273-pow-sixteen-sub-pow-four`: `273 ∣ n^16 - n^4` over `ℤ`, by a finite `ZMod 273` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_273_pow_sixteen_sub_pow_four (n : ℤ) : (273 : ℤ) ∣ n ^ 16 - n ^ 4 := by
  have h : ∀ m : ZMod 273, m ^ 16 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 4 : ℤ) : ZMod 273) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 4) 273).mp hz
  exact_mod_cast hdvd
