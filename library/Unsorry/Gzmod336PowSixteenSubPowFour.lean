import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-336-pow-sixteen-sub-pow-four`: `336 ∣ n^16 - n^4` over `ℤ`, by a finite `ZMod 336` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_336_pow_sixteen_sub_pow_four (n : ℤ) : (336 : ℤ) ∣ n ^ 16 - n ^ 4 := by
  have h : ∀ m : ZMod 336, m ^ 16 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 4 : ℤ) : ZMod 336) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 4) 336).mp hz
  exact_mod_cast hdvd
