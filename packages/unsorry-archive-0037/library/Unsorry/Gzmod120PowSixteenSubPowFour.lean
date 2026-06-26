import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-120-pow-sixteen-sub-pow-four`: `120 ∣ n^16 - n^4` over `ℤ`, by a finite `ZMod 120` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_120_pow_sixteen_sub_pow_four (n : ℤ) : (120 : ℤ) ∣ n ^ 16 - n ^ 4 := by
  have h : ∀ m : ZMod 120, m ^ 16 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 4 : ℤ) : ZMod 120) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 4) 120).mp hz
  exact_mod_cast hdvd
