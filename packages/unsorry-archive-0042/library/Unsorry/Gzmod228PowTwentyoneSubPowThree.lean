import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-228-pow-twentyone-sub-pow-three`: `228 ∣ n^21 - n^3` over `ℤ`, by a finite `ZMod 228` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_228_pow_twentyone_sub_pow_three (n : ℤ) : (228 : ℤ) ∣ n ^ 21 - n ^ 3 := by
  have h : ∀ m : ZMod 228, m ^ 21 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 3 : ℤ) : ZMod 228) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 3) 228).mp hz
  exact_mod_cast hdvd
