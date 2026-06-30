import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-105-pow-nineteen-sub-pow-seven`: `105 ∣ n^19 - n^7` over `ℤ`, by a finite `ZMod 105` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_105_pow_nineteen_sub_pow_seven (n : ℤ) : (105 : ℤ) ∣ n ^ 19 - n ^ 7 := by
  have h : ∀ m : ZMod 105, m ^ 19 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 7 : ℤ) : ZMod 105) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 7) 105).mp hz
  exact_mod_cast hdvd
