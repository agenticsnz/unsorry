import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-102-pow-twentysix-sub-pow-ten`: `102 ∣ n^26 - n^10` over `ℤ`, by a finite `ZMod 102` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_102_pow_twentysix_sub_pow_ten (n : ℤ) : (102 : ℤ) ∣ n ^ 26 - n ^ 10 := by
  have h : ∀ m : ZMod 102, m ^ 26 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 10 : ℤ) : ZMod 102) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 10) 102).mp hz
  exact_mod_cast hdvd
