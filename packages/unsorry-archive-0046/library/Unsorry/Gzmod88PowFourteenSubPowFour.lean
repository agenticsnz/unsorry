import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-88-pow-fourteen-sub-pow-four`: `88 ∣ n^14 - n^4` over `ℤ`, by a finite `ZMod 88` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_88_pow_fourteen_sub_pow_four (n : ℤ) : (88 : ℤ) ∣ n ^ 14 - n ^ 4 := by
  have h : ∀ m : ZMod 88, m ^ 14 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 4 : ℤ) : ZMod 88) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 4) 88).mp hz
  exact_mod_cast hdvd
