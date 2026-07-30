import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-272-pow-twenty-sub-pow-four`: `272 ∣ n^20 - n^4` over `ℤ`, by a finite `ZMod 272` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_272_pow_twenty_sub_pow_four (n : ℤ) : (272 : ℤ) ∣ n ^ 20 - n ^ 4 := by
  have h : ∀ m : ZMod 272, m ^ 20 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 4 : ℤ) : ZMod 272) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 4) 272).mp hz
  exact_mod_cast hdvd
