import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-54-pow-twentythree-sub-pow-five`: `54 ∣ n^23 - n^5` over `ℤ`, by a finite `ZMod 54` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_54_pow_twentythree_sub_pow_five (n : ℤ) : (54 : ℤ) ∣ n ^ 23 - n ^ 5 := by
  have h : ∀ m : ZMod 54, m ^ 23 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 5 : ℤ) : ZMod 54) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 5) 54).mp hz
  exact_mod_cast hdvd
