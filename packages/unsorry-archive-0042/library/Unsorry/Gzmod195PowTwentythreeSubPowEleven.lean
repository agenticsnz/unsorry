import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-195-pow-twentythree-sub-pow-eleven`: `195 ∣ n^23 - n^11` over `ℤ`, by a finite `ZMod 195` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_195_pow_twentythree_sub_pow_eleven (n : ℤ) : (195 : ℤ) ∣ n ^ 23 - n ^ 11 := by
  have h : ∀ m : ZMod 195, m ^ 23 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 11 : ℤ) : ZMod 195) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 11) 195).mp hz
  exact_mod_cast hdvd
