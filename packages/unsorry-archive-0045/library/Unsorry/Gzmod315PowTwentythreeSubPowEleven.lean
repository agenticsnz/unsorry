import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-315-pow-twentythree-sub-pow-eleven`: `315 ∣ n^23 - n^11` over `ℤ`, by a finite `ZMod 315` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_315_pow_twentythree_sub_pow_eleven (n : ℤ) : (315 : ℤ) ∣ n ^ 23 - n ^ 11 := by
  have h : ∀ m : ZMod 315, m ^ 23 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 11 : ℤ) : ZMod 315) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 11) 315).mp hz
  exact_mod_cast hdvd
