import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-468-pow-nineteen-sub-pow-seven`: `468 ∣ n^19 - n^7` over `ℤ`, by a finite `ZMod 468` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_468_pow_nineteen_sub_pow_seven (n : ℤ) : (468 : ℤ) ∣ n ^ 19 - n ^ 7 := by
  have h : ∀ m : ZMod 468, m ^ 19 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 7 : ℤ) : ZMod 468) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 7) 468).mp hz
  exact_mod_cast hdvd
