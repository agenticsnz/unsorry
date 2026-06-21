import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-252-pow-thirteen-sub-pow-seven`: `252 ∣ n^13 - n^7` over `ℤ`, by a finite `ZMod 252` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_252_pow_thirteen_sub_pow_seven (n : ℤ) : (252 : ℤ) ∣ n ^ 13 - n ^ 7 := by
  have h : ∀ m : ZMod 252, m ^ 13 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 7 : ℤ) : ZMod 252) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 7) 252).mp hz
  exact_mod_cast hdvd
