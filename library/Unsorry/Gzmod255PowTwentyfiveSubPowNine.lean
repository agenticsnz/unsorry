import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-255-pow-twentyfive-sub-pow-nine`: `255 ∣ n^25 - n^9` over `ℤ`, by a finite `ZMod 255` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_255_pow_twentyfive_sub_pow_nine (n : ℤ) : (255 : ℤ) ∣ n ^ 25 - n ^ 9 := by
  have h : ∀ m : ZMod 255, m ^ 25 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 9 : ℤ) : ZMod 255) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 9) 255).mp hz
  exact_mod_cast hdvd
