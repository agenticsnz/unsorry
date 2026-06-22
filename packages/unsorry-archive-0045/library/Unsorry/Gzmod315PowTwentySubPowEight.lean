import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-315-pow-twenty-sub-pow-eight`: `315 ∣ n^20 - n^8` over `ℤ`, by a finite `ZMod 315` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_315_pow_twenty_sub_pow_eight (n : ℤ) : (315 : ℤ) ∣ n ^ 20 - n ^ 8 := by
  have h : ∀ m : ZMod 315, m ^ 20 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 8 : ℤ) : ZMod 315) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 8) 315).mp hz
  exact_mod_cast hdvd
