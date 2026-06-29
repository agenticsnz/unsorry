import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-280-pow-twenty-sub-pow-eight`: `280 ∣ n^20 - n^8` over `ℤ`, by a finite `ZMod 280` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_280_pow_twenty_sub_pow_eight (n : ℤ) : (280 : ℤ) ∣ n ^ 20 - n ^ 8 := by
  have h : ∀ m : ZMod 280, m ^ 20 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 8 : ℤ) : ZMod 280) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 8) 280).mp hz
  exact_mod_cast hdvd
