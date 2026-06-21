import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-210-pow-twenty-sub-pow-eight`: `210 ∣ n^20 - n^8` over `ℤ`, by a finite `ZMod 210` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_210_pow_twenty_sub_pow_eight (n : ℤ) : (210 : ℤ) ∣ n ^ 20 - n ^ 8 := by
  have h : ∀ m : ZMod 210, m ^ 20 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 8 : ℤ) : ZMod 210) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 8) 210).mp hz
  exact_mod_cast hdvd
