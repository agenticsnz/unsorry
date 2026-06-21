import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-228-pow-twentyfour-sub-pow-six`: `228 ∣ n^24 - n^6` over `ℤ`, by a finite `ZMod 228` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_228_pow_twentyfour_sub_pow_six (n : ℤ) : (228 : ℤ) ∣ n ^ 24 - n ^ 6 := by
  have h : ∀ m : ZMod 228, m ^ 24 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 6 : ℤ) : ZMod 228) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 6) 228).mp hz
  exact_mod_cast hdvd
