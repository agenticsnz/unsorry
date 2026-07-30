import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-399-pow-twentyone-sub-pow-three`: `399 ∣ n^21 - n^3` over `ℤ`, by a finite `ZMod 399` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_399_pow_twentyone_sub_pow_three (n : ℤ) : (399 : ℤ) ∣ n ^ 21 - n ^ 3 := by
  have h : ∀ m : ZMod 399, m ^ 21 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 3 : ℤ) : ZMod 399) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 3) 399).mp hz
  exact_mod_cast hdvd
