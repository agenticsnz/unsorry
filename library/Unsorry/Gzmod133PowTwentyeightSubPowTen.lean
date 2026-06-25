import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-133-pow-twentyeight-sub-pow-ten`: `133 ∣ n^28 - n^10` over `ℤ`, by a finite `ZMod 133` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_133_pow_twentyeight_sub_pow_ten (n : ℤ) : (133 : ℤ) ∣ n ^ 28 - n ^ 10 := by
  have h : ∀ m : ZMod 133, m ^ 28 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 28 - n ^ 10 : ℤ) : ZMod 133) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 28 - n ^ 10) 133).mp hz
  exact_mod_cast hdvd
