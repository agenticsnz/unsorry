import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-126-pow-nine-sub-pow-three`: `126 ∣ n^9 - n^3` over `ℤ`, by a finite `ZMod 126` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_126_pow_nine_sub_pow_three (n : ℤ) : (126 : ℤ) ∣ n ^ 9 - n ^ 3 := by
  have h : ∀ m : ZMod 126, m ^ 9 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 9 - n ^ 3 : ℤ) : ZMod 126) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 9 - n ^ 3) 126).mp hz
  exact_mod_cast hdvd
