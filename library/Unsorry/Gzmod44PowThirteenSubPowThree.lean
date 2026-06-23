import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-44-pow-thirteen-sub-pow-three`: `44 ∣ n^13 - n^3` over `ℤ`, by a finite `ZMod 44` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_44_pow_thirteen_sub_pow_three (n : ℤ) : (44 : ℤ) ∣ n ^ 13 - n ^ 3 := by
  have h : ∀ m : ZMod 44, m ^ 13 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 3 : ℤ) : ZMod 44) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 3) 44).mp hz
  exact_mod_cast hdvd
