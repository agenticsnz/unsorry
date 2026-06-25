import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-342-pow-twentythree-sub-pow-five`: `342 ∣ n^23 - n^5` over `ℤ`, by a finite `ZMod 342` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_342_pow_twentythree_sub_pow_five (n : ℤ) : (342 : ℤ) ∣ n ^ 23 - n ^ 5 := by
  have h : ∀ m : ZMod 342, m ^ 23 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 5 : ℤ) : ZMod 342) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 5) 342).mp hz
  exact_mod_cast hdvd
