import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-189-pow-twentynine-sub-pow-eleven`: `189 ∣ n^29 - n^11` over `ℤ`, by a finite `ZMod 189` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_189_pow_twentynine_sub_pow_eleven (n : ℤ) : (189 : ℤ) ∣ n ^ 29 - n ^ 11 := by
  have h : ∀ m : ZMod 189, m ^ 29 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 29 - n ^ 11 : ℤ) : ZMod 189) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 29 - n ^ 11) 189).mp hz
  exact_mod_cast hdvd
