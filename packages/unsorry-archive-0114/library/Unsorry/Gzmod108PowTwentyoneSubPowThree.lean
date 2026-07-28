import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-108-pow-twentyone-sub-pow-three`: `108 ∣ n^21 - n^3` over `ℤ`, by a finite `ZMod 108` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_108_pow_twentyone_sub_pow_three (n : ℤ) : (108 : ℤ) ∣ n ^ 21 - n ^ 3 := by
  have h : ∀ m : ZMod 108, m ^ 21 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 3 : ℤ) : ZMod 108) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 3) 108).mp hz
  exact_mod_cast hdvd
