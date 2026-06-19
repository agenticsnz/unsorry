import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-228-pow-twentynine-sub-pow-eleven`: `228 ∣ n^29 - n^11` over `ℤ`, by a finite `ZMod 228` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_228_pow_twentynine_sub_pow_eleven (n : ℤ) : (228 : ℤ) ∣ n ^ 29 - n ^ 11 := by
  have h : ∀ m : ZMod 228, m ^ 29 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 29 - n ^ 11 : ℤ) : ZMod 228) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 29 - n ^ 11) 228).mp hz
  exact_mod_cast hdvd
