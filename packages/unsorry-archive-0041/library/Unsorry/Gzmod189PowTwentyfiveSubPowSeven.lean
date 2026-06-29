import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-189-pow-twentyfive-sub-pow-seven`: `189 ∣ n^25 - n^7` over `ℤ`, by a finite `ZMod 189` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_189_pow_twentyfive_sub_pow_seven (n : ℤ) : (189 : ℤ) ∣ n ^ 25 - n ^ 7 := by
  have h : ∀ m : ZMod 189, m ^ 25 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 7 : ℤ) : ZMod 189) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 7) 189).mp hz
  exact_mod_cast hdvd
