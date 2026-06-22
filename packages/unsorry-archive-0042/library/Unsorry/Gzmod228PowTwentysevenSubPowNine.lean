import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-228-pow-twentyseven-sub-pow-nine`: `228 ∣ n^27 - n^9` over `ℤ`, by a finite `ZMod 228` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_228_pow_twentyseven_sub_pow_nine (n : ℤ) : (228 : ℤ) ∣ n ^ 27 - n ^ 9 := by
  have h : ∀ m : ZMod 228, m ^ 27 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 9 : ℤ) : ZMod 228) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 9) 228).mp hz
  exact_mod_cast hdvd
