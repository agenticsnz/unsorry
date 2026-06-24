import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-114-pow-twentyseven-sub-pow-nine`: `114 ∣ n^27 - n^9` over `ℤ`, by a finite `ZMod 114` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_114_pow_twentyseven_sub_pow_nine (n : ℤ) : (114 : ℤ) ∣ n ^ 27 - n ^ 9 := by
  have h : ∀ m : ZMod 114, m ^ 27 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 9 : ℤ) : ZMod 114) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 9) 114).mp hz
  exact_mod_cast hdvd
