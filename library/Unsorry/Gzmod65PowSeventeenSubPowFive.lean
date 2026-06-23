import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-65-pow-seventeen-sub-pow-five`: `65 ∣ n^17 - n^5` over `ℤ`, by a finite `ZMod 65` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_65_pow_seventeen_sub_pow_five (n : ℤ) : (65 : ℤ) ∣ n ^ 17 - n ^ 5 := by
  have h : ∀ m : ZMod 65, m ^ 17 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 5 : ℤ) : ZMod 65) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 5) 65).mp hz
  exact_mod_cast hdvd
