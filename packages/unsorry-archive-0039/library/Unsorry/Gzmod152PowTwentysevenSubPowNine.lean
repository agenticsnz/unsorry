import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-152-pow-twentyseven-sub-pow-nine`: `152 ∣ n^27 - n^9` over `ℤ`, by a finite `ZMod 152` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_152_pow_twentyseven_sub_pow_nine (n : ℤ) : (152 : ℤ) ∣ n ^ 27 - n ^ 9 := by
  have h : ∀ m : ZMod 152, m ^ 27 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 9 : ℤ) : ZMod 152) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 9) 152).mp hz
  exact_mod_cast hdvd
