import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-340-pow-nineteen-sub-pow-three`: `340 ∣ n^19 - n^3` over `ℤ`, by a finite `ZMod 340` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_340_pow_nineteen_sub_pow_three (n : ℤ) : (340 : ℤ) ∣ n ^ 19 - n ^ 3 := by
  have h : ∀ m : ZMod 340, m ^ 19 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 3 : ℤ) : ZMod 340) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 3) 340).mp hz
  exact_mod_cast hdvd
