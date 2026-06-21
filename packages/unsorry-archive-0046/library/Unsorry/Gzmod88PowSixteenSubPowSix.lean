import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-88-pow-sixteen-sub-pow-six`: `88 ∣ n^16 - n^6` over `ℤ`, by a finite `ZMod 88` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_88_pow_sixteen_sub_pow_six (n : ℤ) : (88 : ℤ) ∣ n ^ 16 - n ^ 6 := by
  have h : ∀ m : ZMod 88, m ^ 16 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 6 : ℤ) : ZMod 88) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 6) 88).mp hz
  exact_mod_cast hdvd
