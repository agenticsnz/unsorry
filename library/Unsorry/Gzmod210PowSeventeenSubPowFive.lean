import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-210-pow-seventeen-sub-pow-five`: `210 ∣ n^17 - n^5` over `ℤ`, by a finite `ZMod 210` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_210_pow_seventeen_sub_pow_five (n : ℤ) : (210 : ℤ) ∣ n ^ 17 - n ^ 5 := by
  have h : ∀ m : ZMod 210, m ^ 17 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 5 : ℤ) : ZMod 210) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 5) 210).mp hz
  exact_mod_cast hdvd
