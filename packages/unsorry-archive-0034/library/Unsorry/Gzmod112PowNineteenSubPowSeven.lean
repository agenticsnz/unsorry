import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-112-pow-nineteen-sub-pow-seven`: `112 ∣ n^19 - n^7` over `ℤ`, by a finite `ZMod 112` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_112_pow_nineteen_sub_pow_seven (n : ℤ) : (112 : ℤ) ∣ n ^ 19 - n ^ 7 := by
  have h : ∀ m : ZMod 112, m ^ 19 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 7 : ℤ) : ZMod 112) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 7) 112).mp hz
  exact_mod_cast hdvd
