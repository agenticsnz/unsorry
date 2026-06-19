import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-88-pow-thirteen-sub-pow-three`: `88 ∣ n^13 - n^3` over `ℤ`, by a finite `ZMod 88` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_88_pow_thirteen_sub_pow_three (n : ℤ) : (88 : ℤ) ∣ n ^ 13 - n ^ 3 := by
  have h : ∀ m : ZMod 88, m ^ 13 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 3 : ℤ) : ZMod 88) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 3) 88).mp hz
  exact_mod_cast hdvd
