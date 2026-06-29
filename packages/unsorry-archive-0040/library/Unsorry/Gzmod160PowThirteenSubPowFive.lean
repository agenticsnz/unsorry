import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-160-pow-thirteen-sub-pow-five`: `160 ∣ n^13 - n^5` over `ℤ`, by a finite `ZMod 160` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_160_pow_thirteen_sub_pow_five (n : ℤ) : (160 : ℤ) ∣ n ^ 13 - n ^ 5 := by
  have h : ∀ m : ZMod 160, m ^ 13 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 5 : ℤ) : ZMod 160) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 5) 160).mp hz
  exact_mod_cast hdvd
