import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-133-pow-twentyfive-sub-pow-seven`: `133 ∣ n^25 - n^7` over `ℤ`, by a finite `ZMod 133` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_133_pow_twentyfive_sub_pow_seven (n : ℤ) : (133 : ℤ) ∣ n ^ 25 - n ^ 7 := by
  have h : ∀ m : ZMod 133, m ^ 25 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 7 : ℤ) : ZMod 133) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 7) 133).mp hz
  exact_mod_cast hdvd
