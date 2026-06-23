import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-44-pow-fifteen-sub-pow-five`: `44 ∣ n^15 - n^5` over `ℤ`, by a finite `ZMod 44` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_44_pow_fifteen_sub_pow_five (n : ℤ) : (44 : ℤ) ∣ n ^ 15 - n ^ 5 := by
  have h : ∀ m : ZMod 44, m ^ 15 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 5 : ℤ) : ZMod 44) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 5) 44).mp hz
  exact_mod_cast hdvd
