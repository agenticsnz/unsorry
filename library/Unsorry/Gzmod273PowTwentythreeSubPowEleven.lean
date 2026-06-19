import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-273-pow-twentythree-sub-pow-eleven`: `273 ∣ n^23 - n^11` over `ℤ`, by a finite `ZMod 273` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_273_pow_twentythree_sub_pow_eleven (n : ℤ) : (273 : ℤ) ∣ n ^ 23 - n ^ 11 := by
  have h : ∀ m : ZMod 273, m ^ 23 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 11 : ℤ) : ZMod 273) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 11) 273).mp hz
  exact_mod_cast hdvd
