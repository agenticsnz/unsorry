import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-280-pow-seventeen-sub-pow-five`: `280 ∣ n^17 - n^5` over `ℤ`, by a finite `ZMod 280` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_280_pow_seventeen_sub_pow_five (n : ℤ) : (280 : ℤ) ∣ n ^ 17 - n ^ 5 := by
  have h : ∀ m : ZMod 280, m ^ 17 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 5 : ℤ) : ZMod 280) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 5) 280).mp hz
  exact_mod_cast hdvd
