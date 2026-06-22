import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-96-pow-thirteen-sub-pow-five`: `96 ∣ n^13 - n^5` over `ℤ`, by a finite `ZMod 96` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_96_pow_thirteen_sub_pow_five (n : ℤ) : (96 : ℤ) ∣ n ^ 13 - n ^ 5 := by
  have h : ∀ m : ZMod 96, m ^ 13 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 5 : ℤ) : ZMod 96) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 5) 96).mp hz
  exact_mod_cast hdvd
