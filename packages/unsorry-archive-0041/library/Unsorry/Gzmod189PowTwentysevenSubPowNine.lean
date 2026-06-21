import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-189-pow-twentyseven-sub-pow-nine`: `189 ∣ n^27 - n^9` over `ℤ`, by a finite `ZMod 189` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_189_pow_twentyseven_sub_pow_nine (n : ℤ) : (189 : ℤ) ∣ n ^ 27 - n ^ 9 := by
  have h : ∀ m : ZMod 189, m ^ 27 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 9 : ℤ) : ZMod 189) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 9) 189).mp hz
  exact_mod_cast hdvd
