import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-342-pow-twentyone-sub-pow-three`: `342 ∣ n^21 - n^3` over `ℤ`, by a finite `ZMod 342` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_342_pow_twentyone_sub_pow_three (n : ℤ) : (342 : ℤ) ∣ n ^ 21 - n ^ 3 := by
  have h : ∀ m : ZMod 342, m ^ 21 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 3 : ℤ) : ZMod 342) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 3) 342).mp hz
  exact_mod_cast hdvd
