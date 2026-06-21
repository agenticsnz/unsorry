import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-234-pow-twenty-sub-pow-eight`: `234 ∣ n^20 - n^8` over `ℤ`, by a finite `ZMod 234` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_234_pow_twenty_sub_pow_eight (n : ℤ) : (234 : ℤ) ∣ n ^ 20 - n ^ 8 := by
  have h : ∀ m : ZMod 234, m ^ 20 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 8 : ℤ) : ZMod 234) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 8) 234).mp hz
  exact_mod_cast hdvd
