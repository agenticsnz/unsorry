import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-136-pow-twentyone-sub-pow-five`: `136 ∣ n^21 - n^5` over `ℤ`, by a finite `ZMod 136` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_136_pow_twentyone_sub_pow_five (n : ℤ) : (136 : ℤ) ∣ n ^ 21 - n ^ 5 := by
  have h : ∀ m : ZMod 136, m ^ 21 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 5 : ℤ) : ZMod 136) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 5) 136).mp hz
  exact_mod_cast hdvd
