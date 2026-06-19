import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-216-pow-twentyeight-sub-pow-ten`: `216 ∣ n^28 - n^10` over `ℤ`, by a finite `ZMod 216` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_216_pow_twentyeight_sub_pow_ten (n : ℤ) : (216 : ℤ) ∣ n ^ 28 - n ^ 10 := by
  have h : ∀ m : ZMod 216, m ^ 28 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 28 - n ^ 10 : ℤ) : ZMod 216) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 28 - n ^ 10) 216).mp hz
  exact_mod_cast hdvd
