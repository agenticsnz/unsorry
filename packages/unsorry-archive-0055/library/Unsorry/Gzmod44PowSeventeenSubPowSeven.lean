import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-44-pow-seventeen-sub-pow-seven`: `44 ∣ n^17 - n^7` over `ℤ`, by a finite `ZMod 44` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_44_pow_seventeen_sub_pow_seven (n : ℤ) : (44 : ℤ) ∣ n ^ 17 - n ^ 7 := by
  have h : ∀ m : ZMod 44, m ^ 17 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 7 : ℤ) : ZMod 44) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 7) 44).mp hz
  exact_mod_cast hdvd
