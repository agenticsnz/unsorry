import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-136-pow-twentyfive-sub-pow-nine`: `136 ∣ n^25 - n^9` over `ℤ`, by a finite `ZMod 136` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_136_pow_twentyfive_sub_pow_nine (n : ℤ) : (136 : ℤ) ∣ n ^ 25 - n ^ 9 := by
  have h : ∀ m : ZMod 136, m ^ 25 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 9 : ℤ) : ZMod 136) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 9) 136).mp hz
  exact_mod_cast hdvd
