import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-136-pow-nineteen-sub-pow-three`: `136 ∣ n^19 - n^3` over `ℤ`, by a finite `ZMod 136` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_136_pow_nineteen_sub_pow_three (n : ℤ) : (136 : ℤ) ∣ n ^ 19 - n ^ 3 := by
  have h : ∀ m : ZMod 136, m ^ 19 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 3 : ℤ) : ZMod 136) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 3) 136).mp hz
  exact_mod_cast hdvd
