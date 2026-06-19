import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-170-pow-twentyfive-sub-pow-nine`: `170 ∣ n^25 - n^9` over `ℤ`, by a finite `ZMod 170` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_170_pow_twentyfive_sub_pow_nine (n : ℤ) : (170 : ℤ) ∣ n ^ 25 - n ^ 9 := by
  have h : ∀ m : ZMod 170, m ^ 25 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 9 : ℤ) : ZMod 170) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 9) 170).mp hz
  exact_mod_cast hdvd
