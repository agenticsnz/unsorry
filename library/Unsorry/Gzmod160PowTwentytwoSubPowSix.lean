import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-160-pow-twentytwo-sub-pow-six`: `160 ∣ n^22 - n^6` over `ℤ`, by a finite `ZMod 160` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_160_pow_twentytwo_sub_pow_six (n : ℤ) : (160 : ℤ) ∣ n ^ 22 - n ^ 6 := by
  have h : ∀ m : ZMod 160, m ^ 22 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 6 : ℤ) : ZMod 160) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 6) 160).mp hz
  exact_mod_cast hdvd
