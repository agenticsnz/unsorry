import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-2-pow-seven-sub-pow-four`: `2 ∣ n^7 - n^4` over `ℤ`, by a finite `ZMod 2` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_2_pow_seven_sub_pow_four (n : ℤ) : (2 : ℤ) ∣ n ^ 7 - n ^ 4 := by
  have h : ∀ m : ZMod 2, m ^ 7 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 7 - n ^ 4 : ℤ) : ZMod 2) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 7 - n ^ 4) 2).mp hz
  exact_mod_cast hdvd
