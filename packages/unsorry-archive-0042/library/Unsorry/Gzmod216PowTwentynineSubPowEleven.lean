import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-216-pow-twentynine-sub-pow-eleven`: `216 ∣ n^29 - n^11` over `ℤ`, by a finite `ZMod 216` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_216_pow_twentynine_sub_pow_eleven (n : ℤ) : (216 : ℤ) ∣ n ^ 29 - n ^ 11 := by
  have h : ∀ m : ZMod 216, m ^ 29 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 29 - n ^ 11 : ℤ) : ZMod 216) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 29 - n ^ 11) 216).mp hz
  exact_mod_cast hdvd
