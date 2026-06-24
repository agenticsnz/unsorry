import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-66-pow-seventeen-sub-pow-seven`: `66 ∣ n^17 - n^7` over `ℤ`, by a finite `ZMod 66` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_66_pow_seventeen_sub_pow_seven (n : ℤ) : (66 : ℤ) ∣ n ^ 17 - n ^ 7 := by
  have h : ∀ m : ZMod 66, m ^ 17 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 7 : ℤ) : ZMod 66) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 7) 66).mp hz
  exact_mod_cast hdvd
