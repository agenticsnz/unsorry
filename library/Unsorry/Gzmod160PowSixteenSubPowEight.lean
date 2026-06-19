import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-160-pow-sixteen-sub-pow-eight`: `160 ∣ n^16 - n^8` over `ℤ`, by a finite `ZMod 160` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_160_pow_sixteen_sub_pow_eight (n : ℤ) : (160 : ℤ) ∣ n ^ 16 - n ^ 8 := by
  have h : ∀ m : ZMod 160, m ^ 16 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 8 : ℤ) : ZMod 160) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 8) 160).mp hz
  exact_mod_cast hdvd
