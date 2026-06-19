import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-60-pow-seven-sub-pow-three`: `60 ∣ n^7 - n^3` over `ℤ`, by a finite `ZMod 60` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_60_pow_seven_sub_pow_three (n : ℤ) : (60 : ℤ) ∣ n ^ 7 - n ^ 3 := by
  have h : ∀ m : ZMod 60, m ^ 7 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 7 - n ^ 3 : ℤ) : ZMod 60) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 7 - n ^ 3) 60).mp hz
  exact_mod_cast hdvd
