import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-152-pow-twentythree-sub-pow-five`: `152 ∣ n^23 - n^5` over `ℤ`, by a finite `ZMod 152` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_152_pow_twentythree_sub_pow_five (n : ℤ) : (152 : ℤ) ∣ n ^ 23 - n ^ 5 := by
  have h : ∀ m : ZMod 152, m ^ 23 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 5 : ℤ) : ZMod 152) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 5) 152).mp hz
  exact_mod_cast hdvd
