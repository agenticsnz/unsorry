import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-171-pow-twentyeight-sub-pow-ten`: `171 ∣ n^28 - n^10` over `ℤ`, by a finite `ZMod 171` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_171_pow_twentyeight_sub_pow_ten (n : ℤ) : (171 : ℤ) ∣ n ^ 28 - n ^ 10 := by
  have h : ∀ m : ZMod 171, m ^ 28 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 28 - n ^ 10 : ℤ) : ZMod 171) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 28 - n ^ 10) 171).mp hz
  exact_mod_cast hdvd
