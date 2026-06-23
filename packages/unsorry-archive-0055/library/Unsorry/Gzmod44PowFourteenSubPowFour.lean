import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-44-pow-fourteen-sub-pow-four`: `44 ∣ n^14 - n^4` over `ℤ`, by a finite `ZMod 44` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_44_pow_fourteen_sub_pow_four (n : ℤ) : (44 : ℤ) ∣ n ^ 14 - n ^ 4 := by
  have h : ∀ m : ZMod 44, m ^ 14 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 4 : ℤ) : ZMod 44) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 4) 44).mp hz
  exact_mod_cast hdvd
