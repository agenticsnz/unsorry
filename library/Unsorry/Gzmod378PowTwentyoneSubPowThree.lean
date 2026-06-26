import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-378-pow-twentyone-sub-pow-three`: `378 ∣ n^21 - n^3` over `ℤ`, by a finite `ZMod 378` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_378_pow_twentyone_sub_pow_three (n : ℤ) : (378 : ℤ) ∣ n ^ 21 - n ^ 3 := by
  have h : ∀ m : ZMod 378, m ^ 21 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 3 : ℤ) : ZMod 378) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 3) 378).mp hz
  exact_mod_cast hdvd
