import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-208-pow-seventeen-sub-pow-five`: `208 ∣ n^17 - n^5` over `ℤ`, by a finite `ZMod 208` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_208_pow_seventeen_sub_pow_five (n : ℤ) : (208 : ℤ) ∣ n ^ 17 - n ^ 5 := by
  have h : ∀ m : ZMod 208, m ^ 17 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 5 : ℤ) : ZMod 208) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 5) 208).mp hz
  exact_mod_cast hdvd
