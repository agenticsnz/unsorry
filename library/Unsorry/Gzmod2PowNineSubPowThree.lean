import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-2-pow-nine-sub-pow-three`: `2 ∣ n^9 - n^3` over `ℤ`, by a finite `ZMod 2` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_2_pow_nine_sub_pow_three (n : ℤ) : (2 : ℤ) ∣ n ^ 9 - n ^ 3 := by
  have h : ∀ m : ZMod 2, m ^ 9 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 9 - n ^ 3 : ℤ) : ZMod 2) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 9 - n ^ 3) 2).mp hz
  exact_mod_cast hdvd
