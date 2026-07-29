import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-130-pow-twentyone-sub-pow-nine`: `130 ∣ n^21 - n^9` over `ℤ`, by a finite `ZMod 130` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_130_pow_twentyone_sub_pow_nine (n : ℤ) : (130 : ℤ) ∣ n ^ 21 - n ^ 9 := by
  have h : ∀ m : ZMod 130, m ^ 21 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 9 : ℤ) : ZMod 130) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 9) 130).mp hz
  exact_mod_cast hdvd
