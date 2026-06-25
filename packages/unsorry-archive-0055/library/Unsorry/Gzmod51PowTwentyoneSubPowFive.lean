import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-51-pow-twentyone-sub-pow-five`: `51 ∣ n^21 - n^5` over `ℤ`, by a finite `ZMod 51` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_51_pow_twentyone_sub_pow_five (n : ℤ) : (51 : ℤ) ∣ n ^ 21 - n ^ 5 := by
  have h : ∀ m : ZMod 51, m ^ 21 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 5 : ℤ) : ZMod 51) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 5) 51).mp hz
  exact_mod_cast hdvd
