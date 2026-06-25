import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-108-pow-twentythree-sub-pow-five`: `108 ∣ n^23 - n^5` over `ℤ`, by a finite `ZMod 108` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_108_pow_twentythree_sub_pow_five (n : ℤ) : (108 : ℤ) ∣ n ^ 23 - n ^ 5 := by
  have h : ∀ m : ZMod 108, m ^ 23 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 5 : ℤ) : ZMod 108) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 5) 108).mp hz
  exact_mod_cast hdvd
