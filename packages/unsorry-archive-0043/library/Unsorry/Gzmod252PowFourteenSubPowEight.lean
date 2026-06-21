import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-252-pow-fourteen-sub-pow-eight`: `252 ∣ n^14 - n^8` over `ℤ`, by a finite `ZMod 252` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_252_pow_fourteen_sub_pow_eight (n : ℤ) : (252 : ℤ) ∣ n ^ 14 - n ^ 8 := by
  have h : ∀ m : ZMod 252, m ^ 14 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 8 : ℤ) : ZMod 252) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 8) 252).mp hz
  exact_mod_cast hdvd
