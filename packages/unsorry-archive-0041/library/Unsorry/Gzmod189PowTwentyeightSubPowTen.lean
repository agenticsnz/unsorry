import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-189-pow-twentyeight-sub-pow-ten`: `189 ∣ n^28 - n^10` over `ℤ`, by a finite `ZMod 189` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_189_pow_twentyeight_sub_pow_ten (n : ℤ) : (189 : ℤ) ∣ n ^ 28 - n ^ 10 := by
  have h : ∀ m : ZMod 189, m ^ 28 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 28 - n ^ 10 : ℤ) : ZMod 189) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 28 - n ^ 10) 189).mp hz
  exact_mod_cast hdvd
