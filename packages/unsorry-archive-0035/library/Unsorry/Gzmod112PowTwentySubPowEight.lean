import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-112-pow-twenty-sub-pow-eight`: `112 ∣ n^20 - n^8` over `ℤ`, by a finite `ZMod 112` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_112_pow_twenty_sub_pow_eight (n : ℤ) : (112 : ℤ) ∣ n ^ 20 - n ^ 8 := by
  have h : ∀ m : ZMod 112, m ^ 20 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 8 : ℤ) : ZMod 112) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 8) 112).mp hz
  exact_mod_cast hdvd
