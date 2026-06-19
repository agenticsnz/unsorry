import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-336-pow-twenty-sub-pow-eight`: `336 ∣ n^20 - n^8` over `ℤ`, by a finite `ZMod 336` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_336_pow_twenty_sub_pow_eight (n : ℤ) : (336 : ℤ) ∣ n ^ 20 - n ^ 8 := by
  have h : ∀ m : ZMod 336, m ^ 20 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 8 : ℤ) : ZMod 336) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 8) 336).mp hz
  exact_mod_cast hdvd
