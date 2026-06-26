import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-171-pow-twentythree-sub-pow-five`: `171 ∣ n^23 - n^5` over `ℤ`, by a finite `ZMod 171` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_171_pow_twentythree_sub_pow_five (n : ℤ) : (171 : ℤ) ∣ n ^ 23 - n ^ 5 := by
  have h : ∀ m : ZMod 171, m ^ 23 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 5 : ℤ) : ZMod 171) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 5) 171).mp hz
  exact_mod_cast hdvd
