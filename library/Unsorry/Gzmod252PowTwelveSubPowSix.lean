import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-252-pow-twelve-sub-pow-six`: `252 ∣ n^12 - n^6` over `ℤ`, by a finite `ZMod 252` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_252_pow_twelve_sub_pow_six (n : ℤ) : (252 : ℤ) ∣ n ^ 12 - n ^ 6 := by
  have h : ∀ m : ZMod 252, m ^ 12 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 12 - n ^ 6 : ℤ) : ZMod 252) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 12 - n ^ 6) 252).mp hz
  exact_mod_cast hdvd
