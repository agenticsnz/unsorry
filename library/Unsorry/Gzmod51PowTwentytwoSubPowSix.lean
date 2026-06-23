import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-51-pow-twentytwo-sub-pow-six`: `51 ∣ n^22 - n^6` over `ℤ`, by a finite `ZMod 51` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_51_pow_twentytwo_sub_pow_six (n : ℤ) : (51 : ℤ) ∣ n ^ 22 - n ^ 6 := by
  have h : ∀ m : ZMod 51, m ^ 22 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 6 : ℤ) : ZMod 51) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 6) 51).mp hz
  exact_mod_cast hdvd
