import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-255-pow-twenty-sub-pow-four`: `255 ∣ n^20 - n^4` over `ℤ`, by a finite `ZMod 255` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_255_pow_twenty_sub_pow_four (n : ℤ) : (255 : ℤ) ∣ n ^ 20 - n ^ 4 := by
  have h : ∀ m : ZMod 255, m ^ 20 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 4 : ℤ) : ZMod 255) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 4) 255).mp hz
  exact_mod_cast hdvd
