import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-40-pow-seven-sub-pow-three`: `40 ∣ n^7 - n^3` over `ℤ`, by a finite `ZMod 40` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_40_pow_seven_sub_pow_three (n : ℤ) : (40 : ℤ) ∣ n ^ 7 - n ^ 3 := by
  have h : ∀ m : ZMod 40, m ^ 7 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 7 - n ^ 3 : ℤ) : ZMod 40) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 7 - n ^ 3) 40).mp hz
  exact_mod_cast hdvd
